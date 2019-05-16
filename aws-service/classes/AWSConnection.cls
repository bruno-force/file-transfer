global with sharing class AWSConnection {

    global Enum AWS_SERVICE {S3}
    global Enum AWS_AUTH_METHOD {AWS4}

    private String client_id;
    private String client_secret;
    private AWS_SERVICE service;
    private AWS_AUTH_METHOD authMethod;
    private String region;
    private Map<String,String> headers;

    private Datetime now = Datetime.now();

    global AWSConnection(String client_id, String client_secret, AWS_AUTH_METHOD authMethod) {
        this.client_id = client_id;
        this.client_secret = client_secret;
        this.authMethod = authMethod;
    }

    global AWSConnection(String client_id, String client_secret, String authMethod) {
        this.client_id = client_id;
        this.client_secret = client_secret;
        this.authMethod = this.stringToAuthMethods.get(authMethod);
    }

    private final Map<AWS_SERVICE, String> services = new Map<AWS_SERVICE, String>{
        AWS_SERVICE.S3 => 's3'
    };

    private final Map<String, AWS_SERVICE> stringToServices = new Map<String, AWS_SERVICE>{
        's3' => AWS_SERVICE.S3 
    };

    private final Map<AWS_AUTH_METHOD, String> authMethods = new Map<AWS_AUTH_METHOD, String>{
        AWS_AUTH_METHOD.AWS4 => 'AWS4-HMAC-SHA256'
    };

    private final Map<String, AWS_AUTH_METHOD> stringToAuthMethods = new Map<String, AWS_AUTH_METHOD>{
        'AWS4-HMAC-SHA256' => AWS_AUTH_METHOD.AWS4
    };

    /**
    * Property Accesors
    */

    global AWSBucket getBucket(String bucketName, String region) {
        return new AWSBucket(this, bucketName, region);
    }

    global String getClientId() {
        return this.client_id;
    }

    global String getClientSecret() {
        return this.client_secret;
    }

    global String getAuthMethod() {
        return this.authMethods.get(this.authMethod);
    }

    global String getService() {
        if(this.service == null) throw new AWS_Exception('Service is not set');
        return this.services.get(this.service);
    }

    global String getRegion() {
        return this.region;
    }

    global Map<String, String> getHeaders() {
        if (this.headers == null) this.headers = new Map<String, String>();
        return this.headers;
    }

    /**
    * Property Setters
    */

    global AWSConnection setService(AWS_SERVICE service) {
        this.service = service;
        return this;
    }

    global AWSConnection setService(String service) {
        this.service = this.stringToServices.get(service);
        return this;
    }

    global String setRegion(String r) {
        return this.region = r;
    }

    global AWSConnection setHeaders(Map<String, String> headers) {
        this.headers = headers;
        return this;
    }

    global AWSConnection addHeader(String key, String value) {
        this.getHeaders().put(key, value);
        return this;
    }

    global AWSConnection addHeaders(Map<String, String> headers) {
        this.getHeaders().putAll(headers);
        return this;
    }

    global Boolean isS3() {
        if(this.service == null) throw new AWS_Exception('Service is not set');
        return this.service == AWS_SERVICE.S3;
    }

    global HttpRequest signedRequest(String method, Url endpoint, Map<String,String> headers, Blob payload, Boolean presign) {
        
        //defaults
        if (headers == null) headers = new Map<String,String>();
        if (payload == null) payload = Blob.valueOf('');
        if (presign == null) presign = false;

        //assemble
        String termination = 'aws4_request';
        String iso8601date = this.now.formatGmt('yyyyMMdd');
        String iso8601time = this.now.formatGmt('yyyyMMdd\'T\'HHmmss\'Z\'');
        String credentialScope = iso8601date + '/' + this.getRegion() + '/' + this.getService() + '/' + termination;

        //prepare headers
        headers.put('Host', endpoint.getHost());
        String signedHeaders = AWSConnectionHelper.signedHeadersFor(headers);

        //handle spaces and special characters in paths
        String spec = '';
        spec += endpoint.getProtocol() + '://';
        spec += endpoint.getHost();
        spec += AWSConnectionHelper.rfc3986For(endpoint.getPath(), false);
        if (endpoint.getQuery() != null) spec += '?' + endpoint.getQuery();

        //prepare parameters
        PageReference pr = new PageReference(spec);
        Map<String,String> parameters = pr.getParameters();
        parameters.put('X-Amz-Algorithm', 'AWS4-HMAC-SHA256');
        parameters.put('X-Amz-Credential', this.getClientId() + '/' + credentialScope);
        parameters.put('X-Amz-Date', iso8601time);
        parameters.put('X-Amz-Expires', '86400');
        parameters.put('X-Amz-SignedHeaders', signedHeaders);

        //Task 1: Create a Canonical Request for Signature Version 4
        //https://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
        String canonicalRequest = AWSConnectionHelper.canonicalMethodFor(method)
            + '\n' + AWSConnectionHelper.canonicalUriFor(endpoint.toExternalForm())
            + '\n' + AWSConnectionHelper.canonicalQueryStringFor(parameters)
            + '\n' + AWSConnectionHelper.canonicalHeadersFor(headers)
            + '\n' + AWSConnectionHelper.signedHeadersFor(headers)
            + '\n' + (presign ? 'UNSIGNED-PAYLOAD' : AWSConnectionHelper.hexEncodedHashFor(payload))
        ;

        //Task 2: Create a String to Sign for Signature Version 4
        //https://docs.aws.amazon.com/general/latest/gr/sigv4-create-string-to-sign.html
        String algorithm = 'AWS4-HMAC-SHA256';
        String canonicalRequestHash = AWSConnectionHelper.hexEncodedHashFor(Blob.valueOf(canonicalRequest));
        String stringToSign = algorithm + '\n' + iso8601time + '\n' + credentialScope + '\n' + canonicalRequestHash;

        //Task 3: Calculate the AWS Signature Version 4
        //https://docs.aws.amazon.com/general/latest/gr/sigv4-calculate-signature.html
        Blob keySecret = Blob.valueOf('AWS4' + this.getClientSecret());
        Blob keyDate = Crypto.generateMac('hmacSHA256', Blob.valueOf(iso8601date), keySecret);
        Blob keyRegion = Crypto.generateMac('hmacSHA256', Blob.valueOf(this.getRegion()), keyDate);
        Blob keyService = Crypto.generateMac('hmacSHA256', Blob.valueOf(this.getService()), keyRegion);
        Blob keySigning = Crypto.generateMac('hmacSHA256', Blob.valueOf('aws4_request'), keyService);
        Blob blobToSign = Blob.valueOf(stringToSign);
        Blob hmac = Crypto.generateMac('hmacSHA256', blobToSign, keySigning);

        //Task 4: Add the Signing Information to the Request
        //https://docs.aws.amazon.com/general/latest/gr/sigv4-add-signature-to-request.html
        if (!presign) headers.put('X-Amz-Content-Sha256', AWSConnectionHelper.hexEncodedHashFor(payload));
        String signature = EncodingUtil.convertToHex(hmac);
        parameters.put('X-Amz-Signature', signature);

        //prepare request
        HttpRequest request = new HttpRequest();
        request.setMethod(method);
        request.setEndpoint(pr.getUrl());

        if (payload != Blob.valueOf('')) request.setBodyAsBlob(payload); //affects http method
        for (String header : headers.keySet()) request.setHeader(header, headers.get(header));

        return request;
    }

    global class AWS_Exception extends Exception {}
}
