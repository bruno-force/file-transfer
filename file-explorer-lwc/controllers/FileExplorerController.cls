public with sharing class FileExplorerController {
    
    @AuraEnabled(cacheable=true)
    public static Object getIdentifierValue( String identifier, String objectType, Id recordId) {
        return database.query(String.format(
            'SELECT {0} FROM {1} WHERE Id =:recordId LIMIT 1'
        , new String[]{identifier, objectType}))[0].get(identifier);
    }

    @AuraEnabled
    public static AWSContent[] getFilesFromRecord(String connection, String identifier) {
        AWSServiceSettings__c settings = getConnectionSettings(connection);
        return new AWSConnection(settings.AccessKey__c, settings.SecretKey__c, settings.SignatureAlgorithm__c)
            .setService(settings.Service__c)
            .getBucket(settings.S3BucketName__c, settings.Region__c)
            .addPrefix(settings.RootFolder__c + '/' + identifier)
            .listAll();
    }

    @AuraEnabled
    public static String getUploadPresigned(String connection, String identifier, String name) {
        AWSServiceSettings__c settings = getConnectionSettings(connection);
        return  new AWSConnection(settings.AccessKey__c, settings.SecretKey__c, settings.SignatureAlgorithm__c)
            .setService(settings.Service__c)
            .getBucket(settings.S3BucketName__c, settings.Region__c)
            .getUploadPresigned(settings.RootFolder__c + '/' + identifier + '/' + EncodingUtil.urlEncode(name, 'UTF-8'));
    }

    private static AWSServiceSettings__c getConnectionSettings(String settingName) {
        return AWSServiceSettings__c.getAll().get(settingName);
    }
}