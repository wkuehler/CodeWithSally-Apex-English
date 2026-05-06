# LWC Conventions

## Receiving Record Context
```javascript
import { LightningElement, api, wire } from 'lwc';

export default class MyComponent extends LightningElement {
    @api recordId;       // current record's Id
    @api objectApiName;  // e.g. 'Account', 'Case', 'Opportunity'
}
```

## Wiring Apex and Refreshing After DML
```javascript
import getNotes from '@salesforce/apex/MyController.getNotes';
import { refreshApex } from '@salesforce/apex';

@wire(getNotes, { recordId: '$recordId', objectApiName: '$objectApiName' })
wiredNotes(result) {
    this._wiredResult = result;
}

// After a save/delete, force a reload:
await refreshApex(this._wiredResult);
```

## js-meta.xml — Targeting Specific Objects on Record Pages
```xml
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>66.0</apiVersion>
    <isExposed>true</isExposed>
    <targets>
        <target>lightning__RecordPage</target>
    </targets>
    <targetConfigs>
        <targetConfig targets="lightning__RecordPage">
            <objects>
                <object>Account</object>
                <object>Case</object>
                <object>Opportunity</object>
            </objects>
        </targetConfig>
    </targetConfigs>
</LightningComponentBundle>
```
