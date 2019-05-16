import { LightningElement, api } from 'lwc';

export default class FileGalleryItem extends LightningElement {
    @api file;

    selectFile() { 
        this.dispatchEvent(new CustomEvent('selectfile', { detail: this.file, bubbles: true, composed: true })); 
    }

    get isImage() { return this.file.type === 'Image' }

    get isDocument() { return this.file.type === 'Document' }

    get isUnknown() { return !this.isImage && !this.isDocument }

    get formattedName() { return decodeURIComponent(this.file.name).replace('+', ' '); }
}