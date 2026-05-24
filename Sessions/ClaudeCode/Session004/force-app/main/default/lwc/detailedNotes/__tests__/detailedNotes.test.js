import { createElement } from 'lwc';
import DetailedNotes from 'c/detailedNotes';
import getNotes from '@salesforce/apex/DetailedNoteController.getNotes';

jest.mock(
    '@salesforce/apex/DetailedNoteController.getNotes',
    () => {
        const { createApexTestWireAdapter } = require('@salesforce/wire-service-jest-util');
        return { default: createApexTestWireAdapter(jest.fn()) };
    },
    { virtual: true }
);

jest.mock('@salesforce/apex/DetailedNoteController.saveNote', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/DetailedNoteController.updateNote', () => ({ default: jest.fn() }), { virtual: true });
jest.mock('@salesforce/apex/DetailedNoteController.deleteNote', () => ({ default: jest.fn() }), { virtual: true });

const MOCK_NOTES = [
    {
        id: 'a001',
        title: 'First Note',
        body: '<p>Body 1</p>',
        createdByName: 'Alice',
        createdById: 'user001',
        createdDate: '2026-05-01T10:00:00.000Z',
        canEdit: true,
        sourceLabel: null
    },
    {
        id: 'a002',
        title: 'Second Note',
        body: '<p>Body 2</p>',
        createdByName: 'Bob',
        createdById: 'user002',
        createdDate: '2026-05-02T10:00:00.000Z',
        canEdit: false,
        sourceLabel: 'Case: Billing Issue'
    }
];

describe('detailedNotes', () => {
    let element;

    beforeEach(() => {
        element = createElement('c-detailed-notes', { is: DetailedNotes });
        element.recordId = 'record001';
        element.objectApiName = 'Account';
        document.body.appendChild(element);
    });

    afterEach(() => {
        document.body.removeChild(element);
    });

    it('renders note tiles after wire emits data', async () => {
        getNotes.emit(MOCK_NOTES);
        await Promise.resolve();

        const tiles = element.shadowRoot.querySelectorAll('.note-tile');
        expect(tiles.length).toBe(2);
    });

    it('shows title and author on each tile', async () => {
        getNotes.emit(MOCK_NOTES);
        await Promise.resolve();

        const tiles = element.shadowRoot.querySelectorAll('.note-tile');
        expect(tiles[0].textContent).toContain('First Note');
        expect(tiles[0].textContent).toContain('Alice');
    });

    it('shows source badge when sourceLabel is present', async () => {
        getNotes.emit(MOCK_NOTES);
        await Promise.resolve();

        const badges = element.shadowRoot.querySelectorAll('.source-badge');
        expect(badges.length).toBe(1);
        expect(badges[0].textContent).toContain('Case: Billing Issue');
    });

    it('renders new note button', () => {
        const btn = element.shadowRoot.querySelector('[data-id="new-note-btn"]');
        expect(btn).not.toBeNull();
    });

    it('clicking a note tile displays the note body', async () => {
        getNotes.emit(MOCK_NOTES);
        await Promise.resolve();

        const tile = element.shadowRoot.querySelector('[data-id="a001"]');
        tile.click();
        await Promise.resolve();

        const viewer = element.shadowRoot.querySelector('[data-id="note-viewer"]');
        expect(viewer).not.toBeNull();
    });

    it('shows edit and delete buttons when canEdit is true', async () => {
        getNotes.emit(MOCK_NOTES);
        await Promise.resolve();

        element.shadowRoot.querySelector('[data-id="a001"]').click();
        await Promise.resolve();

        const editBtn = element.shadowRoot.querySelector('[data-id="edit-btn"]');
        const deleteBtn = element.shadowRoot.querySelector('[data-id="delete-btn"]');
        expect(editBtn).not.toBeNull();
        expect(deleteBtn).not.toBeNull();
    });

    it('clicking New Note shows the editor form', async () => {
        getNotes.emit(MOCK_NOTES);
        await Promise.resolve();

        element.shadowRoot.querySelector('[data-id="new-note-btn"]').click();
        await Promise.resolve();

        const form = element.shadowRoot.querySelector('[data-id="editor-form"]');
        expect(form).not.toBeNull();
    });

    it('clicking Cancel hides the editor form', async () => {
        getNotes.emit(MOCK_NOTES);
        await Promise.resolve();

        element.shadowRoot.querySelector('[data-id="new-note-btn"]').click();
        await Promise.resolve();

        element.shadowRoot.querySelector('[data-id="cancel-btn"]').click();
        await Promise.resolve();

        expect(element.shadowRoot.querySelector('[data-id="editor-form"]')).toBeNull();
        const placeholder = element.shadowRoot.querySelector('.slds-text-color_weak');
        expect(placeholder).not.toBeNull();
    });

    it('title input enforces maxlength of 100', async () => {
        getNotes.emit([]);
        await Promise.resolve();

        element.shadowRoot.querySelector('[data-id="new-note-btn"]').click();
        await Promise.resolve();

        const titleInput = element.shadowRoot.querySelector('[data-id="title-input"]');
        expect(Number(titleInput.maxLength)).toBe(100);
    });

    it('hides edit and delete buttons when canEdit is false', async () => {
        getNotes.emit(MOCK_NOTES);
        await Promise.resolve();

        element.shadowRoot.querySelector('[data-id="a002"]').click();
        await Promise.resolve();

        const editBtn = element.shadowRoot.querySelector('[data-id="edit-btn"]');
        const deleteBtn = element.shadowRoot.querySelector('[data-id="delete-btn"]');
        expect(editBtn).toBeNull();
        expect(deleteBtn).toBeNull();
    });
});
