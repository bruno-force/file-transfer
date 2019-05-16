global with sharing class AWSContent {
    
    @AuraEnabled global Boolean isRoot {get;set;}
    @AuraEnabled global Boolean isFolder {get;set;}
    @AuraEnabled global String id {get;set;}
    @AuraEnabled global String name {get;set;}
    @AuraEnabled global String path {get;set;}
    @AuraEnabled global String url {get;set;}
    @AuraEnabled global String type {get;set;}
    @AuraEnabled global String mimeType {get;set;}
    @AuraEnabled global Integer size {get;set;}
    @AuraEnabled global DateTime lastModified {get;set;}

    private static final String FOLDER_DELIMITER = '/';
    private static final String EXTENSION_DELIMITER = '.';

    private static final String EXTENSION_IMAGE = 'jpg,jpeg,png,gif,bmp';
    private static final String EXTENSION_DOCUMENT = 'doc,docx,pdf,xls';

    private static final String FILE_TYPE_FOLDER = 'Folder';
    private static final String FILE_TYPE_IMAGE = 'Image';
    private static final String FILE_TYPE_DOCUMENT = 'Document';
    private static final String FILE_TYPE_OTHER = 'Other';

    global AWSContent() {}

    global AWSContent(String path, String etag, Integer size, DateTime lastMod) {
        this.id = etag;
        this.path = path;
        this.size = size;
        this.lastModified = lastMod;

        this.name = this.getFileName();
        this.type = this.getFileType();
        this.mimeType = this.getMimeType();
        this.isFolder = this.isFolder();
        this.isRoot = this.isRoot();
    }

    global Boolean isFolder() {
        return this.path.endsWith(FOLDER_DELIMITER);
    }

    global Boolean isRoot() {
        return this.isFolder() && this.path.countMatches(FOLDER_DELIMITER) == 1;
    }

    global String getFileName() {     
        String path = this.path.removeEnd(FOLDER_DELIMITER);
        return path.substring(path.lastIndexOf(FOLDER_DELIMITER)+1);
    }

    global String getMimeType() {
        return this.getFileName().substring(this.getFileName().lastIndexOf(EXTENSION_DELIMITER)+1);
    }

    global String getPathEncoded() {
        String filename = this.getFileName();
        //return this.path.replace(filename, EncodingUtil.urlEncode(filename, 'UTF-8'));
        //return this.path.replace(' ', '+');
        return this.path.replace(' ', '+');
    }

    global AWSContent setUrl(String url) {
        this.url = url;
        return this;
    }

    // FILE CATEGORY
    global String getFileType() {  

        String fileType, ext = this.getMimeType();

        if(this.isFolder()) fileType = FILE_TYPE_FOLDER; 
        else if(EXTENSION_IMAGE.contains(ext)) fileType = FILE_TYPE_IMAGE;
        else if(EXTENSION_DOCUMENT.contains(ext)) fileType = FILE_TYPE_DOCUMENT;
        else fileType = FILE_TYPE_OTHER;

        return fileType;
    }
}
