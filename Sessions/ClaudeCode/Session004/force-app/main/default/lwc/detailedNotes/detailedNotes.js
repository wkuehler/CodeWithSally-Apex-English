import { LightningElement, api, wire } from 'lwc';
import getNotes from '@salesforce/apex/DetailedNoteController.getNotes';
import saveNote from '@salesforce/apex/DetailedNoteController.saveNote';
import updateNote from '@salesforce/apex/DetailedNoteController.updateNote';
import deleteNote from '@salesforce/apex/DetailedNoteController.deleteNote';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class DetailedNotes extends LightningElement {
    @api recordId;
    @api objectApiName;

    selectedNoteId = null;
    showEditor = false;
    editorTitle = '';
    editorBody = '';
    editingNoteId = null;

    _wiredResult;

    @wire(getNotes, { recordId: '$recordId', objectApiName: '$objectApiName' })
    wiredNotes(result) {
        this._wiredResult = result;
    }

    get noteList() {
        if (!this._wiredResult?.data) return [];
        return this._wiredResult.data.map((n) => ({
            ...n,
            formattedDate: new Date(n.createdDate).toLocaleDateString(),
            tileClass:
                'note-tile' + (n.id === this.selectedNoteId ? ' note-tile--selected' : '')
        }));
    }

    get hasNotes() {
        return this.noteList.length > 0;
    }

    get selectedNote() {
        if (!this.selectedNoteId) return null;
        return this.noteList.find((n) => n.id === this.selectedNoteId) || null;
    }

    handleNoteSelect(event) {
        this.selectedNoteId = event.currentTarget.dataset.id;
        this.showEditor = false;
    }

    handleNewNote() {
        this.editingNoteId = null;
        this.editorTitle = '';
        this.editorBody = '';
        this.showEditor = true;
    }

    handleEdit() {
        this.editingNoteId = this.selectedNoteId;
        this.editorTitle = this.selectedNote.title;
        this.editorBody = this.selectedNote.body;
        this.showEditor = true;
    }

    handleTitleChange(event) {
        this.editorTitle = event.target.value;
    }

    handleBodyChange(event) {
        this.editorBody = event.target.value;
    }

    handleCancel() {
        this.showEditor = false;
    }

    async handleSave() {
        try {
            if (this.editingNoteId) {
                await updateNote({
                    noteId: this.editingNoteId,
                    title: this.editorTitle,
                    body: this.editorBody
                });
            } else {
                await saveNote({
                    title: this.editorTitle,
                    body: this.editorBody,
                    recordId: this.recordId,
                    objectApiName: this.objectApiName
                });
            }
            await refreshApex(this._wiredResult);
            this.showEditor = false;
            this.dispatchEvent(
                new ShowToastEvent({ title: 'Success', message: 'Note saved.', variant: 'success' })
            );
        } catch (e) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: e.body?.message || 'Save failed.',
                    variant: 'error'
                })
            );
        }
    }

    async handleDelete() {
        try {
            await deleteNote({ noteId: this.selectedNoteId });
            this.selectedNoteId = null;
            await refreshApex(this._wiredResult);
            this.dispatchEvent(
                new ShowToastEvent({ title: 'Success', message: 'Note deleted.', variant: 'success' })
            );
        } catch (e) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: e.body?.message || 'Delete failed.',
                    variant: 'error'
                })
            );
        }
    }
}
