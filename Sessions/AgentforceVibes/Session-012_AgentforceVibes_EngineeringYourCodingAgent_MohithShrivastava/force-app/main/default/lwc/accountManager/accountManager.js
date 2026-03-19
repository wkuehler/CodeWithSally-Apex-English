import { LightningElement, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAccounts from '@salesforce/apex/AccountService.getAccounts';
import createAccount from '@salesforce/apex/AccountService.createAccount';
import updateAccount from '@salesforce/apex/AccountService.updateAccount';
import deleteAccount from '@salesforce/apex/AccountService.deleteAccount';

const COLUMNS = [
    { label: 'Name', fieldName: 'Name', type: 'text', editable: true },
    { label: 'Industry', fieldName: 'Industry', type: 'text', editable: true },
    { label: 'Phone', fieldName: 'Phone', type: 'phone', editable: true },
    { label: 'Website', fieldName: 'Website', type: 'url', editable: true },
    {
        type: 'action',
        typeAttributes: {
            rowActions: [{ label: 'Delete', name: 'delete' }]
        }
    }
];

const INDUSTRY_OPTIONS = [
    { label: 'Technology', value: 'Technology' },
    { label: 'Finance', value: 'Finance' },
    { label: 'Healthcare', value: 'Healthcare' },
    { label: 'Energy', value: 'Energy' },
    { label: 'Consulting', value: 'Consulting' },
    { label: 'Retail', value: 'Retail' },
    { label: 'Manufacturing', value: 'Manufacturing' },
    { label: 'Education', value: 'Education' }
];

export default class AccountManager extends LightningElement {
    @track accounts = [];
    @track error = null;
    @track isLoading = false;
    @track showModal = false;
    @track draftValues = [];
    @track newAccount = {};

    columns = COLUMNS;
    wiredAccountsResult;

    get industryOptions() {
        return INDUSTRY_OPTIONS;
    }

    get hasAccounts() {
        return !this.isLoading && !this.error && this.accounts.length > 0;
    }

    get showEmptyState() {
        return !this.isLoading && !this.error && this.accounts.length === 0;
    }

    @wire(getAccounts)
    wiredAccounts(result) {
        this.wiredAccountsResult = result;
        const { data, error } = result;
        if (data) {
            this.accounts = data;
            this.error = null;
        } else if (error) {
            this.error = error.body?.message || 'An error occurred while loading accounts.';
            this.accounts = [];
        }
    }

    handleNewAccount() {
        this.newAccount = {};
        this.showModal = true;
    }

    handleCloseModal() {
        this.showModal = false;
        this.newAccount = {};
    }

    handleFieldChange(event) {
        const field = event.target.dataset.field;
        this.newAccount = { ...this.newAccount, [field]: event.detail.value };
    }

    async handleCreateAccount() {
        if (!this.newAccount.Name) {
            this.showToast('Error', 'Account Name is required.', 'error');
            return;
        }

        this.isLoading = true;
        try {
            await createAccount({ acc: this.newAccount });
            this.showToast('Success', 'Account created successfully.', 'success');
            this.handleCloseModal();
            await refreshApex(this.wiredAccountsResult);
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Failed to create account.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async handleSave(event) {
        const updatedFields = event.detail.draftValues;
        this.isLoading = true;

        try {
            const promises = updatedFields.map(draft => {
                const fields = { ...draft, Id: draft.Id };
                return updateAccount({ acc: fields });
            });
            await Promise.all(promises);
            this.showToast('Success', 'Accounts updated successfully.', 'success');
            this.draftValues = [];
            await refreshApex(this.wiredAccountsResult);
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Failed to update accounts.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;

        if (action.name === 'delete') {
            this.isLoading = true;
            try {
                await deleteAccount({ accountId: row.Id });
                this.showToast('Success', 'Account deleted successfully.', 'success');
                await refreshApex(this.wiredAccountsResult);
            } catch (error) {
                this.showToast('Error', error.body?.message || 'Failed to delete account.', 'error');
            } finally {
                this.isLoading = false;
            }
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
