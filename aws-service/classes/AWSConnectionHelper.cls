global with sharing class AWSConnectionHelper {
    /**
     * Start with the HTTP request method (GET, PUT, POST, etc.), followed by a newline character.
     * https://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
     */
    global static String canonicalMethodFor(String method) {
        return method.toUpperCase();
    }

    /**
     * The canonical URI is the URI-encoded version of the absolute path component of the URI, which is everything in
     * the URI from the HTTP host to the question mark character
     * http://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
     */
    global static String canonicalUriFor(String endpoint) {
        Url uri = new Url(endpoint);
        return rfc3986For(uri.getPath(), false);
    }

    /**
     * To construct the canonical query string, complete the following steps:
     * a. URI-encode each parameter name and value.
     * b. Sort the encoded parameter names by character code in ascending order (ASCII order).
     * c. Build the canonical query string by starting with the first parameter name in the sorted list.
     * d. For each parameter, append the URI-encoded parameter name, followed by '=' followed by the URI-encoded value
     * e. Append the character '&' (ASCII code 38) after each parameter value, except for the last value in the list.
     * https://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
     */
    global static String canonicalQueryStringFor(Map<String,String> parameters) {
        
        //sort keys by ascii code
        List<String> sortedKeys = new List<String>(parameters.keySet());
        sortedKeys.sort();
        
        //prepare values
        List<String> canonicalParameters = new List<String>();
        for (String sortedKey : sortedKeys) canonicalParameters.add(
            sortedKey + 
            '=' + 
            rfc3986For(parameters.get(sortedKey), true)
        );
        
        return String.join(canonicalParameters, '&');
    }

    /**
     * To create the canonical headers list, convert all header names to lowercase and remove leading spaces and
     * trailing spaces. Convert sequential spaces in the header value to a single space.
     * https://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
     */
    global static String canonicalHeadersFor(Map<String,String> key2value) {
        
        //lowercase header keys
        Map<String,String> lower2value = new Map<String,String>();
        for (String key : key2value.keySet()) lower2value.put(key.toLowerCase(), key2value.get(key).trim().replaceAll('\\s+', ' '));
        
        //sort canonical keys by ascii code
        List<String> sortedKeys = new List<String>(lower2value.keySet());
        sortedKeys.sort();
        
        //prepare values
        List<String> canonicalHeaders = new List<String>();
        for (String sortedKey : sortedKeys) canonicalHeaders.add(sortedKey + ':' + lower2value.get(sortedKey) + '\n');
        
        return String.join(canonicalHeaders, '');
    }

    /**
     * Build the signed headers list by iterating through the collection of header names, sorted by lowercase character
     * code. For each header name except the last, append a semicolon (';') to the header name to separate it from the
     * following header name.
     * https://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
     */
    global static String signedHeadersFor(Map<String,String> headers) {
        
        //lowercase header keys
        List<String> keys = new List<String>(headers.keySet());
        for (Integer i = 0; i < keys.size(); i++) keys.set(i, keys[i].toLowerCase());
        
        //sort ascii
        keys.sort();
        
        //prepare values
        List<String> signedHeaders = new List<String>();
        for (String key : keys) signedHeaders.add(key);
        
        return String.join(signedHeaders, ';');
    }

    /**
     * The hashed canonical request must be represented as a string of lowercase hexademical characters.
     * https://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
     */
    global static String hexEncodedHashFor(Blob data) {
        Blob hash = Crypto.generateDigest('SHA256', data);
        return EncodingUtil.convertToHex(hash);
    }

    /**
     * Caution: The standard UriEncode functions provided by your development platform may not work because of
     * differences in implementation and related ambiguity in the underlying RFCs. We recommend that you write your own
     * custom UriEncode function to ensure that your encoding will work.
     * https://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-query-string-auth.html
     */
    global static String rfc3986For(String characters, Boolean encodeSlash) {
        String result = '';
        for (Integer i = 0; i < characters.length(); i++) {
            String character = characters.substring(i, i + 1);
            
            if (
                (character >= 'A' && character <= 'Z') || 
                (character >= 'a' && character <= 'z') || 
                (character >= '0' && character <= '9') || 
                character == '_' || 
                character == '-' || 
                character == '~' || 
                character == '.'
            ) {
                result += character;
            } else if (character == '/') {
                result += encodeSlash ? '%2F' : character;
            } else {
                result += '%' + EncodingUtil.convertToHex(Blob.valueOf(character)).toUpperCase();
            }
        }
        
        return result;
    }
}
