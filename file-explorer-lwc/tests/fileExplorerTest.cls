@isTest
public with sharing class fileExplorerTest {
    
    @TestSetup static void makeData(){
        insert new Case();
        insert new AWSServiceSettings__c(
            Name = 'S3-Mock',
            AccessKey__c = 'TEST-KEY',
            SecretKey__c = 'SECRET',
            SignatureAlgorithm__c = 'AWS4-HMAC-SHA256',
            Service__c = 's3',
            S3BucketName__c = 'BUCKET-O-TEST',
            Region__c = 'TEST',
            RootFolder__c = 'TEST'
        );
    }

    @isTest static void getIdentifier() {
        Case c = [SELECT Id FROM Case LIMIT 1];
        Test.startTest();
        FileExplorerController.getIdentifierValue('Id', 'Case', c.Id);
        Test.stopTest();
    }

    @isTest static void getBucket() {
        
        Test.setMock(HttpCalloutMock.class, new AWSCallout());
        Test.startTest();
        FileExplorerController.getFilesFromRecord('S3-Mock', 'Id');
        Test.stopTest();
    }
    @isTest static void getUploadPresigned() {
        Test.startTest();
        FileExplorerController.getUploadPresigned('S3-Mock', 'Id', 'test.png');
        Test.stopTest();
    }

    public class AWSCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            String xml = 
            '<?xml version="1.0" encoding="UTF-8"?>' +
            '<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">' +
                '<Name>bucket</Name>' +
                '<Prefix/>' +
                '<KeyCount>205</KeyCount>' +
                '<MaxKeys>1000</MaxKeys>' +
                '<IsTruncated>false</IsTruncated>' +
                '<Contents>' +
                    '<Key>my-image.jpg</Key>' +
                    '<LastModified>2009-10-12T17:50:30.000Z</LastModified>' +
                    '<ETag>&quot;fba9dede5f27731c9771645a39863328&quot;</ETag>' +
                    '<Size>434234</Size>' +
                    '<StorageClass>STANDARD</StorageClass>' +
                '</Contents>' +
            '</ListBucketResult>';

            res.setBody(xml);
            res.setStatusCode(200);
            return res;
        }
    }
}
