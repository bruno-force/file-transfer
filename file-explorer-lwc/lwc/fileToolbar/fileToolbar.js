import { LightningElement, track } from 'lwc';

export default class FileToolbar extends LightningElement {
    
    @track searchQuery;

    filter(event) {
        this.dispatchEvent(new CustomEvent('search', { detail: event.target.value }))
    }
}