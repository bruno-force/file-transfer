global with sharing class AWSParser {

    global Enum CONNECTION_NODE { ERROR }
    global Enum BUCKET_NODE { ROOT, NAME, PREFIX, MARKER, MAX_KEYS, IS_TRUNCATED, CONTENTS }
    global Enum CONTENT_NODE { KEY, LAST_MOD, ETAG, SIZE, STORAGE_CLASS }

    private Dom.Document xmlDom;
  
    global AWSParser(Dom.Document xmlDom) {
        this.xmlDom = xmlDom;
    }

    private final Map<CONNECTION_NODE, String> connectionNodes = new Map<CONNECTION_NODE, String>{
        CONNECTION_NODE.ERROR => 'Error'
    };

    private final Map<BUCKET_NODE, String> bucketNodes = new Map<BUCKET_NODE, String>{
        BUCKET_NODE.ROOT => 'ListBucketResult',
        BUCKET_NODE.NAME => 'Name',
        BUCKET_NODE.PREFIX => 'Prefix',
        BUCKET_NODE.MARKER => 'Marker',
        BUCKET_NODE.MAX_KEYS => 'MaxKeys',
        BUCKET_NODE.IS_TRUNCATED => 'IsTruncated',
        BUCKET_NODE.CONTENTS => 'Contents'
    };

    private final Map<CONTENT_NODE, String> contentNodes = new Map<CONTENT_NODE, String>{
        CONTENT_NODE.KEY => 'Key',
        CONTENT_NODE.LAST_MOD => 'LastModified',
        CONTENT_NODE.ETAG => 'ETag',
        CONTENT_NODE.SIZE => 'Size',
        CONTENT_NODE.STORAGE_CLASS => 'StorageClass'
    };

    global AWSContent[] parseBucket() {

        AWSContent[] bucketContents = new AWSContent[]{};
        Dom.XmlNode root = this.xmlDom.getRootElement();

        if(root.getName() == this.connectionNodes.get(CONNECTION_NODE.ERROR)) {
            throw new AWSConnection.AWS_Exception('ERROR FETCHING BUCKET >>> ' + this.xmlDom.toXmlString() ); 
        }

        if(root.getName() != this.bucketNodes.get(BUCKET_NODE.ROOT)) 
            throw new AWSConnection.AWS_Exception('Bucket response not correct, root element name doens\'t match >>> ' + this.xmlDom.toXmlString() );

        for(Dom.XmlNode node: root.getChildElements()) {

            if(node.getName() == this.bucketNodes.get(BUCKET_NODE.CONTENTS)) {
                String path, etag;
                Integer size;
                DateTime lastMod;

                for(Dom.XmlNode contentNode: node.getChildElements()) {
                    if(contentNode.getName() == this.contentNodes.get(CONTENT_NODE.KEY)) { path = contentNode.getText(); }
                    else if (contentNode.getName() == this.contentNodes.get(CONTENT_NODE.ETAG)) { etag = contentNode.getText(); }
                    else if (contentNode.getName() == this.contentNodes.get(CONTENT_NODE.SIZE)) { size = Integer.valueOf(contentNode.getText()); }
                    else if (contentNode.getName() == this.contentNodes.get(CONTENT_NODE.LAST_MOD)) { lastMod = DateTime.valueOf(contentNode.getText().replace('T',' ').replace('Z', '')); }
                }
                bucketContents.add(new AWSContent(path,etag, size, lastMod));
            }
        }

        return bucketContents;
    }
}
