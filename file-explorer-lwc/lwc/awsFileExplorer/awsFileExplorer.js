import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getIdentifierValue from '@salesforce/apex/FileExplorerController.getIdentifierValue';
import getFilesFromRecord from '@salesforce/apex/FileExplorerController.getFilesFromRecord';
import getUploadPresigned from '@salesforce/apex/FileExplorerController.getUploadPresigned';

import files from '@salesforce/label/c.files';
import upload from '@salesforce/label/c.upload';
import typeAll from '@salesforce/label/c.all';
import typeImage from '@salesforce/label/c.image';
import typeOther from '@salesforce/label/c.other';
import typeDocument from '@salesforce/label/c.document';

const PREVIEW_MODAL = 'preview';
const UPLOAD_MODAL = 'upload';

export default class AwsFileExplorer extends LightningElement {

    label = {
        files, upload,
        type: {
            all: typeAll,
            image: typeImage,
            other: typeOther,
            document: typeDocument
        }
    };

    @api recordId;
    @api objectApiName;
    @api flexipageRegionWidth;

    @api connection;
    @api recordIdentifier;
    
    @track data;
    @track fileType;

    @track showModal;
    @track modalType;
    @track modalData;

    @track recordIdentifierValue;
    @track error;

    constructor() {
        super();
        this.fileType = 'all';
        this.showModal = false;
    }

    /**
     * File Data Connectors
     */

    @wire(getIdentifierValue, { identifier: '$recordIdentifier', objectType: '$objectApiName', recordId: '$recordId' })
    recordCallback({ error, data }) {
        if (data) {
            this.recordIdentifierValue = data;
            this.fetchFilesForTicket();
        } else if (error) {
            this.handleError(error);
        }
    }

    fetchFilesForTicket() {
        getFilesFromRecord({ connection: this.connection, identifier: this.recordIdentifierValue })
            .then(result => {
                this.data = result;
            })
            .catch(error => {
                this.handleError(error);
                this.data = undefined;
            });
    }

    refreshFiles() {
        this.fetchFilesForTicket();
    }

    /**
     *  Getters
     */

    get filesToDisplay() {
        return (this.data)? this.data.filter(file => this.matchType(file)): null;
    }

    get mimeTypes() {
        return (this.data)? Object.values(this.countFileTypes(this.data)): null;
    }

    get hostname() {
        return location.protocol + '//' + location.hostname;
    }

    /**
     * File Filter Methods
     */

    matchType(file) {
        return (file.type.toLowerCase() !== 'folder' && (this.fileType.toLowerCase() === 'all' || file.type.toLowerCase() === this.fileType.toLowerCase()));
    }

    matchQuery(file) {
        return !(this.fileFilter && this.fileFilter.length > 0) || this.nameFormatted(file.name).toLowerCase().includes(this.fileFilter.toLowerCase());
    }

    /**
     * Page Events
     */

    onFileTypeSelect(event) {
        if (event.detail.name !== UPLOAD_MODAL) {
            this.fileType = event.detail.name;
        }
    }

    onCloseModal() {
        this.closeModal();
    }

    onSelectFile(event) {
        this.openPreviewModal(event.detail);
    }

    onDownloadFile(event) {
        let a = document.createElement('a');
        a.href = event.detail.src;
        a.download = event.detail.name;
        a.target = '_blank';
        a.click();
    }

    onUploadFile(event) {
        const file = event.detail,
            b64 = file.src.substring(file.src.indexOf(',') + 1),
            blob = this.b64toBlob(b64, 'application/octet-stream');

        // Upload directly to S3 with presigned URI
        getUploadPresigned({ connection: this.connection, identifier: this.recordIdentifierValue, name: event.detail.name })
        .then(result => {
            fetch(result, {
                method: 'PUT',
                mode: 'cors',
                headers: { 
                    'Content-Type': 'application/octet-stream',
                    'Access-Control-Allow-Origin': this.hostname,
                    'Access-Control-Allow-Methods' : 'PUT',
                    'Access-Control-Allow-Headers' : 'Content-Type'
                },
                body: blob
            })
            .then(response => {
                if(response.status === 200) this.refreshFiles();
                this.closeModal();
            })
            .catch(error => this.handleError(error));
        })
        .catch(error => this.handleError(error));
    }

    onListFilter(event) {
        this.fileFilter = event.detail;
    }

    /**
     * Helpers
     */

    openUploadModal() {
        this.openModal(UPLOAD_MODAL);
    }

    openPreviewModal(file) {
        this.openModal(PREVIEW_MODAL, {
            file: file,
        });
    }

    openModal(type, data) {
        this.modalType = type;
        this.modalData = data;
        this.showModal = true;
    }

    closeModal() {
        this.modalType = null;
        this.modalData = {};
        this.showModal = false;
    }

    nameFormatted(name) {
        return name.split('.')[0];
    }

    countFileTypes(data) {
        let c = {
            'All': {
                id: 'all',
                label: this.label.type.all,
                count: (data) ? data.length : 0
            }
        };
        
        if (data) {
            for (let f of data) {
                if (f.type.toLowerCase() !== 'folder') {
                    if (c.hasOwnProperty(f.type)) {
                        c[f.type].count++;
                    } else {
                        c[f.type] = {
                            id: f.type,
                            label: this.label.type[f.type.toLowerCase()],
                            count: 1
                        };
                    }
                } else {
                    c.All.count--;
                }
            }
        }
        return c;
    }

    b64toBlob(b64Data, contentType) {
        const byteCharacters = atob(b64Data);
        const byteArrays = [];
        const sliceSize = 512;

        for (let offset = 0; offset < byteCharacters.length; offset += sliceSize) {
            const slice = byteCharacters.slice(offset, offset + sliceSize);

            const byteNumbers = new Array(slice.length);
            for (let i = 0; i < slice.length; i++) {
                byteNumbers[i] = slice.charCodeAt(i);
            }

            const byteArray = new Uint8Array(byteNumbers);

            byteArrays.push(byteArray);
        }

        const blob = new Blob(byteArrays, { type: contentType });
        return blob;
    }

    handleError(error) {
        let message = 'Unknown error';
        if (Array.isArray(error.body)) {
            message = error.body.map(e => e.message).join(', ');
        } else if (typeof error.body.message === 'string') {
            message = error.body.message;
        }
        this.error = message;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message,
                variant: 'error',
            }),
        );
    }
}   
