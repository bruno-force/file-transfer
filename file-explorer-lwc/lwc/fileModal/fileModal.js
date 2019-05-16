import { LightningElement, api, track } from 'lwc';

import upload from '@salesforce/label/c.upload';
import download from '@salesforce/label/c.download';
import close from '@salesforce/label/c.close';

import titleUpload from '@salesforce/label/c.fileupload';
import titlePreview from '@salesforce/label/c.filePreview';

const PREVIEW_MODAL = 'preview';
const UPLOAD_MODAL = 'upload';

export default class FileModal extends LightningElement {

    label = {
        action: {
            upload, download, close
        },
        title: {
            upload: titleUpload,
            preview: titlePreview
        }
    };

    @api modalType;
    @api modalData;

    @track reader;

    @track fileReady;
    @track file;

    /**
     * Modal | Common
     */

    constructor() {
        super();
        this.setupReader();
    }

    connectedCallback() {
        const self = this;
        this.keyEvent = function (event) {
            if (event.key.toLowerCase() === 'escape') {
                self.dispatchEvent(new CustomEvent('close'))
            }
        }
        document.addEventListener('keydown', this.keyEvent);
    }

    disconnectedCallback() {
        document.removeEventListener('keydown', this.keyEvent);
    }

    get isPreview() { return this.modalType === PREVIEW_MODAL }

    get isUpload() { return this.modalType === UPLOAD_MODAL }

    close() { this.dispatchEvent(new CustomEvent('close')) }

    /**
     * Preview Modal
     */

    get fileMeta() { return this.modalData.file }

    get fileSource() { return this.modalData.file.url }

    get isImage() { return this.fileMeta.type === 'Image' }

    get isDocument() { return this.fileMeta.type === 'Document' }
    
    get isUnknown() { return !this.isImage && !this.isDocument }

    download() {
        this.dispatchEvent(new CustomEvent('downloadfile', {
            detail: {
                name: this.fileMeta.name,
                src: this.fileSource
            }
        }));
    }

    /**
     * Upload Modal
     */

    get acceptedFormats() {
        return ['.pdf', '.doc', '.docx', '.jpg', '.jpeg', '.png'];
    }

    get isFileLoaded() {
        return this.fileReady;
    }

    get uploadDisabled() {
        return !this.isFileLoaded;
    }

    upload() {
        this.loadingFile = true;
        this.dispatchEvent(new CustomEvent('uploadfile', {
            detail: {
                type: 'local',
                name: this.file.name,
                src: this.reader.result
            }
        }));
    }

    setupReader() {
        let self = this;
        this.reader = new FileReader();

        this.reader.addEventListener('load', function () {
            self.fileReady = true;
            self.loadingFile = false;
        }, false);
    }

    handleUpload(event) {
        let file = event.detail.files[0];
        if (file) {
            this.file = file;
            this.reader.readAsDataURL(file);
        }
    }
}