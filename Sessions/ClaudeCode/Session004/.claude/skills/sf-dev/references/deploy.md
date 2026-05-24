# Deploying — SF CLI Reference

## Check the default org first
```bash
sf org list   # 🍁 = default org
```

## Deploy all source
```bash
sf project deploy start --target-org <alias>
```

## Check a failed deploy by ID
Useful when terminal output is truncated — grab the Deploy ID from the scrollback
and check the result directly:
```bash
sf project deploy report --job-id <deployId> --target-org <alias> | tail -40
```

## Run Apex tests
```bash
sf apex run test --class-names MyTestClass --result-format human --wait 5 --target-org <alias>
```

## Assign a permission set to yourself
```bash
sf org assign permset --name MyPermissionSet --target-org <alias>
```

## Open the org
```bash
sf org open --target-org <alias>
```
