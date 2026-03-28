import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getMembers from '@salesforce/apex/StudyGroupLeaderboardService.getMembers';

import GROUP_NAME_FIELD from '@salesforce/schema/Study_Group__c.Group_Name__c';
import GOAL_FIELD from '@salesforce/schema/Study_Group__c.Goal__c';
import START_DATE_FIELD from '@salesforce/schema/Study_Group__c.Start_Date__c';
import END_DATE_FIELD from '@salesforce/schema/Study_Group__c.End_Date__c';
import MEMBER_COUNT_FIELD from '@salesforce/schema/Study_Group__c.Member_Count__c';
import MAX_MEMBERS_FIELD from '@salesforce/schema/Study_Group__c.Max_Members__c';
import IS_ACTIVE_FIELD from '@salesforce/schema/Study_Group__c.Is_Active__c';
import DESCRIPTION_FIELD from '@salesforce/schema/Study_Group__c.Description__c';

const GROUP_FIELDS = [
    GROUP_NAME_FIELD,
    GOAL_FIELD,
    START_DATE_FIELD,
    END_DATE_FIELD,
    MEMBER_COUNT_FIELD,
    MAX_MEMBERS_FIELD,
    IS_ACTIVE_FIELD,
    DESCRIPTION_FIELD
];

export default class StudyGroupLeaderboard extends LightningElement {
    @api recordId;

    members = [];
    group;
    error;

    @wire(getRecord, { recordId: '$recordId', fields: GROUP_FIELDS })
    wiredGroup({ data, error }) {
        if (data) {
            this.group = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.group = undefined;
        }
    }

    @wire(getMembers, { studyGroupId: '$recordId' })
    wiredMembers({ data, error }) {
        if (data) {
            this.members = data.map((row) => ({
                ...row,
                xpBarStyle: `width:${row.xpPercent}%; min-width:0.75rem;`
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.members = [];
        }
    }

    get hasGroup() {
        return !!this.group;
    }

    get title() {
        const name =
            getFieldValue(this.group, GROUP_NAME_FIELD) ||
            'Study Group';
        return name;
    }

    get goal() {
        return getFieldValue(this.group, GOAL_FIELD);
    }

    get dateRange() {
        const start = getFieldValue(this.group, START_DATE_FIELD);
        const end = getFieldValue(this.group, END_DATE_FIELD);
        if (!start && !end) {
            return null;
        }
        if (!start) {
            return `– ${end}`;
        }
        if (!end) {
            return `${start} –`;
        }
        return `${start} – ${end}`;
    }

    get membersLabel() {
        const count = getFieldValue(this.group, MEMBER_COUNT_FIELD);
        const max = getFieldValue(this.group, MAX_MEMBERS_FIELD);
        if (count == null || max == null) {
            return null;
        }
        return `${count} / ${max}`;
    }

    get statusLabel() {
        const isActive = getFieldValue(this.group, IS_ACTIVE_FIELD);
        return isActive ? 'Active' : 'Inactive';
    }

    get description() {
        return getFieldValue(this.group, DESCRIPTION_FIELD);
    }
}

