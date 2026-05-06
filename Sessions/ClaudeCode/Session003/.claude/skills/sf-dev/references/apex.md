# Apex Patterns

## Method Annotations
- `@AuraEnabled(cacheable=true)` — for methods called via `@wire`. No DML allowed.
- `@AuraEnabled` — for imperative calls (save, delete, etc.). DML is fine.

## Checking Custom Permissions
```apex
FeatureManagement.checkPermission('MyCustomPermissionDeveloperName')
// Returns true if the running user has the permission
```

Authorization check pattern with override:
```apex
private static void assertCanEdit(String createdById) {
    if (
        createdById != UserInfo.getUserId() &&
        !FeatureManagement.checkPermission('Edit_All_Detailed_Notes')
    ) {
        throw new AuraHandledException(
            'You do not have permission to edit or delete this note.'
        );
    }
}
```

## Sorting Inner Wrapper Classes
Implement `Comparable` on the wrapper and call `List.sort()`:

```apex
public class NoteWrapper implements Comparable {
    public DateTime createdDate;

    public Integer compareTo(Object other) {
        NoteWrapper o = (NoteWrapper) other;
        if (createdDate == o.createdDate) return 0;
        return createdDate > o.createdDate ? -1 : 1; // -1 = newest first
    }
}

List<NoteWrapper> wrappers = new List<NoteWrapper>();
// ... populate ...
wrappers.sort();
```

## with sharing vs without sharing
- `with sharing` — respects org sharing rules. Use on read-only controllers.
- `without sharing` — bypasses sharing. Use (sparingly, with a comment explaining why)
  for DML where the running user might not own the record.
