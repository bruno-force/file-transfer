global with sharing class AWSBucket {
    
    private AWSConnection connection;
    private String name;
    private String prefix;

    global ENUM CONTENT_TYPE {
        CDEFAULT,
        CBLOB,
        CDOCUMENT,
        CBASE64
    }
    
    global AWSBucket(AWSConnection connection, String name, String region) {
        
        if(!connection.isS3()) { /* ERROR | BUCKET CALLOUTS MUST BE S3 SERVICE */ } 
        this.connection = connection;
        this.connection.setRegion(region);
        this.name = name;
    }

    global AWSBucket addPrefix(String prefix) {
        this.prefix = EncodingUtil.urlEncode(prefix, 'UTF-8');
        return this;
    }

    global Url getUrl(String endpoint) {
        return new Url(String.format('https://{0}.{1}.amazonaws.com/{2}/{3}{4}', new List<String> {
            this.connection.getService(),
            this.connection.getRegion(),
            this.getName(),
            String.isNotEmpty(endpoint)?endpoint: '',
            this.hasPrefix()? String.format('?prefix={0}', new String[]{this.getPrefix()}): ''
        }));
    }

    global AWSContent[] listAll() {  
        return this.fetchBucket(null);
    }

    global AWSContent[] listTicket(String endpoint) {  
        return this.fetchBucket(endpoint);
    }

    global String getFileUrl(String filePath) {
        return this.connection.signedRequest('GET', this.getUrl(filePath), this.connection.getHeaders(), null, true).getEndpoint();
    }

    global String getFile(String filePath) { 
        return (String) this.getBucketResponseAs('GET', this.getUrl(filePath), this.connection.getHeaders(), null, true, CONTENT_TYPE.CDEFAULT);
    }

    global String getUploadPresigned(String key) {
        return this.connection.signedRequest('PUT', this.getUrl(key), this.connection.getHeaders(), null, true).getEndpoint();
    }

    global void uploadFileFromString(String key, String payloadString) {       
        this.getBucketResponseAs('PUT', this.getUrl(key), this.connection.getHeaders(), EncodingUtil.base64Decode(payloadString), false, CONTENT_TYPE.CDEFAULT);
    }

    private AWSContent[] fetchBucket(String endpoint) { 

        AWSContent[] files = new AWSParser((DOM.Document)this.getBucketResponseAs(this.getUrl(endpoint), CONTENT_TYPE.CDOCUMENT)).parseBucket();

        // Set presinged url for files
        for(AWSContent file: files) file.setUrl(this.connection.signedRequest('GET', this.getUrl(file.getPathEncoded()), this.connection.getHeaders(), null, true).getEndpoint());
             
        return files;
    }

    private Object getBucketResponseAs(Url endpoint, CONTENT_TYPE contentType) { 
        return this.getBucketResponseAs('GET', endpoint, this.connection.getHeaders(), null, false, contentType);
    }

    private Object getBucketResponseAs(String method, Url endpoint, Map<String,String> headers, Blob payload, Boolean presigned, CONTENT_TYPE contentType) { 

        HttpResponse response = new System.Http().send(this.connection.signedRequest(method, endpoint, headers, payload, true));

        if(response.getStatusCode() != 200) throw new AWSConnection.AWS_Exception(response.getBody());

        if(contentType == CONTENT_TYPE.CBLOB) return response.getBodyAsBlob();
        else if(contentType == CONTENT_TYPE.CDOCUMENT) return response.getBodyDocument();
        else if(contentType == CONTENT_TYPE.CBASE64) return EncodingUtil.base64Encode(response.getBodyAsBlob());

        return response.getBody();
    }

    /**
    *   Property Accesors 
    */
    global String getName() {
        return this.name;
    }

    global String getRegion() {
        return this.connection.getRegion();
    }

    global Boolean hasPrefix() {
        return String.isNotEmpty(this.prefix) && String.isNotBlank(this.prefix);
    }

    global String getPrefix() {
        return this.prefix;
    }
}
