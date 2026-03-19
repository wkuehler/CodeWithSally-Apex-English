# Agentforce Vibes: Hooks

Hooks let you run custom scripts at key moments during an Agentforce Vibes coding session. Think of them as lifecycle callbacks — your code executes when the agent starts a task, writes a file, runs a command, and more.

In this tutorial, we'll build a **PostToolUse** hook that automatically runs **Prettier** and **ESLint** every time the agent writes a file. The agent gets lint feedback inline so it can self-correct without you having to ask.

## Hook Types

Agentforce Vibes supports eight hook types:

| Hook | When It Fires |
|---|---|
| `PreRequest` | Before a prompt is sent to the LLM |
| `PostRequest` | After the LLM responds |
| `PreToolUse` | Before a tool call executes |
| `PostToolUse` | After a tool call completes |
| `PreTask` | When a task begins |
| `PostTask` | When a task ends |
| `OnError` | When an error occurs |
| `ContextUpdate` | When the conversation context changes |

We'll focus on **PostToolUse** — the sweet spot for code-quality automation.

## How Hooks Work

Every hook follows the same contract:

1. **Agentforce Vibes calls your script** as a subprocess
2. **Your script reads JSON from stdin** describing the event (which tool ran, what parameters it used, whether it succeeded)
3. **Your script writes JSON to stdout** telling the agent what to do next

The response JSON has two fields:

```json
{
  "cancel": false,
  "contextModification": "Optional message injected into the conversation"
}
```

- **`cancel`** — set to `true` to abort the current operation (rarely needed)
- **`contextModification`** — a string the agent sees as additional context. Perfect for feeding lint errors back so it can fix them.

Hook scripts live in `.a4drules/hooks/` and are named after their type (e.g., `PostToolUse`). They must be executable.

## What We're Building

Our `PostToolUse` hook will:

1. Detect when the agent calls the `write_to_file` tool
2. Run **Prettier** on the written file to auto-format it
3. Run **ESLint** on `.js` files inside `aura/` or `lwc/` directories
4. Return any lint issues as `contextModification` so the agent can self-correct

This project already has both tools configured:

- **Prettier** (`.prettierrc`) with `prettier-plugin-apex` and `@prettier/plugin-xml`
- **ESLint** (`eslint.config.js`) with Salesforce LWC and Aura rules
- Both installed as devDependencies in `package.json`

## Step 1: Create the Hook Script

Create the file `.a4drules/hooks/PostToolUse`:

```bash
#!/bin/bash
# PostToolUse Hook — Auto-format with Prettier & lint with ESLint

# Read the JSON event from stdin
INPUT=$(cat)

# Extract tool name, file path, and success status
TOOL=$(echo "$INPUT" | python3 -c \
  "import sys,json; print(json.load(sys.stdin).get('postToolUse',{}).get('tool',''))" 2>/dev/null)

FILE_PATH=$(echo "$INPUT" | python3 -c \
  "import sys,json; print(json.load(sys.stdin).get('postToolUse',{}).get('parameters',{}).get('path',''))" 2>/dev/null)

SUCCESS=$(echo "$INPUT" | python3 -c \
  "import sys,json; print(json.load(sys.stdin).get('postToolUse',{}).get('success',False))" 2>/dev/null)
```

The input JSON looks like this:

```json
{
  "taskId": "abc-123",
  "hookName": "PostToolUse",
  "postToolUse": {
    "tool": "write_to_file",
    "parameters": {
      "path": "force-app/main/default/lwc/myComponent/myComponent.js"
    },
    "result": "ok",
    "success": true,
    "durationMs": 42
  }
}
```

## Step 2: Filter to Relevant Events

We only care about successful `write_to_file` calls on file types we can format:

```bash
# Only act on successful write_to_file calls
if [ "$TOOL" != "write_to_file" ] || [ "$SUCCESS" != "True" ] || [ -z "$FILE_PATH" ]; then
    echo '{"cancel": false}'
    exit 0
fi

# Check the file extension
EXT="${FILE_PATH##*.}"
case "$EXT" in
    cls|js|html|xml|css|trigger|cmp|page)
        ;; # supported — continue
    *)
        echo '{"cancel": false}'
        exit 0
        ;;
esac
```

This is important — hooks fire for *every* tool call. Returning `{"cancel": false}` early for irrelevant events keeps things fast.

## Step 3: Run Prettier

```bash
PRETTIER_OUTPUT=$(npx prettier --write "$FILE_PATH" 2>&1)
PRETTIER_EXIT=$?

if [ $PRETTIER_EXIT -ne 0 ]; then
    CONTEXT_PARTS+=("Prettier failed on $FILE_PATH:\n$PRETTIER_OUTPUT")
fi
```

Prettier rewrites the file in place (`--write`). If it fails (e.g., syntax error in Apex), we capture the output for the agent.

## Step 4: Run ESLint on JS Files

```bash
if [ "$EXT" = "js" ]; then
    case "$FILE_PATH" in
        **/aura/**|*aura/*|**/lwc/**|*lwc/*)
            ESLINT_OUTPUT=$(npx eslint "$FILE_PATH" 2>&1)
            ESLINT_EXIT=$?

            if [ $ESLINT_EXIT -ne 0 ]; then
                CONTEXT_PARTS+=("ESLint found issues in $FILE_PATH:\n$ESLINT_OUTPUT")
            fi
            ;;
    esac
fi
```

We only run ESLint on `.js` files inside `aura/` or `lwc/` directories — matching the project's existing lint script (`"lint": "eslint **/{aura,lwc}/**/*.js"`).

## Step 5: Return the Response

```bash
if [ ${#CONTEXT_PARTS[@]} -gt 0 ]; then
    # Escape the combined messages for JSON
    COMBINED=""
    for part in "${CONTEXT_PARTS[@]}"; do
        [ -n "$COMBINED" ] && COMBINED="$COMBINED\n\n"
        COMBINED="$COMBINED$part"
    done

    ESCAPED=$(echo -e "$COMBINED" | python3 -c \
      "import sys,json; print(json.dumps(sys.stdin.read().strip()))")

    echo "{\"cancel\": false, \"contextModification\": $ESCAPED}"
else
    echo '{"cancel": false}'
fi
```

When everything passes, we return `{"cancel": false}` — the agent continues normally. When there are issues, the `contextModification` string gets injected into the conversation, and the agent sees something like:

> ESLint found issues in force-app/main/default/lwc/myComponent/myComponent.js:
> 3:5 error 'unusedVar' is assigned a value but never used no-unused-vars

The agent can then fix the issue in its next action.

## Step 6: Make It Executable

```bash
chmod +x .a4drules/hooks/PostToolUse
```

## Testing the Hook

Pipe sample JSON to verify it works:

```bash
echo '{
  "taskId": "test",
  "hookName": "PostToolUse",
  "postToolUse": {
    "tool": "write_to_file",
    "parameters": {
      "path": "force-app/main/default/lwc/example/example.js"
    },
    "result": "ok",
    "success": true,
    "durationMs": 50
  }
}' | .a4drules/hooks/PostToolUse
```

You should see `{"cancel": false}` (or a `contextModification` if ESLint finds issues in that file).

For a non-matching tool, verify early exit:

```bash
echo '{
  "taskId": "test",
  "hookName": "PostToolUse",
  "postToolUse": {
    "tool": "read_file",
    "parameters": {"path": "README.md"},
    "result": "ok",
    "success": true,
    "durationMs": 10
  }
}' | .a4drules/hooks/PostToolUse
```

This should return `{"cancel": false}` immediately.

## Enabling the Hook

1. Open **Agentforce Vibes** in VS Code
2. Go to the **Hooks** tab
3. Your `PostToolUse` hook should appear automatically (it reads from `.a4drules/hooks/`)
4. Toggle it **on**

From now on, every file the agent writes will be auto-formatted and lint-checked — no manual intervention needed.

## How It Looks in Practice

Here's what happens when you ask the agent to create a new LWC:

1. Agent calls `write_to_file` to create `myComponent.js`
2. Hook fires → Prettier formats the file → ESLint checks it
3. ESLint finds `no-unused-vars` on line 5
4. Hook returns `contextModification` with the error
5. Agent sees the lint error and fixes line 5 in its next action
6. Hook fires again → Prettier formats → ESLint passes
7. Agent continues to the next file

The agent self-corrects without you typing a single follow-up prompt.

## Tips

- **Keep hooks fast.** They run synchronously — a slow hook slows down the entire session. Prettier and ESLint on a single file are quick enough.
- **Always return valid JSON.** If your hook crashes or returns malformed output, the agent session may stall.
- **Use `contextModification` liberally.** It's the primary way to give the agent feedback. Be specific — include file names, line numbers, and error messages.
- **Test outside of Vibes first.** Pipe JSON through your hook on the command line before enabling it in a live session.
