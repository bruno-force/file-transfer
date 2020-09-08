# AWS Service File Explorer

Provides an interface to connect to AWS Services.

## File Explorer [Lightning Web Component]

Dynamic component that can be implemented in any record page, and with provided Connection Settings and given record external identifier will retrieve and upload files from a bucket.

# Usage

## AWS Connection Settings

Create a new entry on AWS Connection Settings

Field | Value
----|----
Name | YOUR-SETTING-IDENTIFIER (will need this later to reference it from the component)
Access Key | IAM Access key
Secret Key | IAM Secret key	
Signature Algorithm	| AWS4-HMAC-SHA256 (DEFAULT)
Service	s3 | AWS Service example: s3 
Region | your-region example: eu-central-1
S3 Bucket Name | your.bucket.name
Root Folder | your/folder/path

## Remote Site Settings

Add a Remote Site Setting for the S3 Region your bucket belongs 

example: https://s3.eu-central-1.amazonaws.com

## CSP trusted sites permission

Add your S3 Region endpoint to CSP permissions

example: https://s3.eu-central-1.amazonaws.com

## IAM user permission policy

Add a policy to the IAM connection user (Add inline policy)

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::your.bucket.name"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::your.bucket.name/*"
            ]
        }
    ]
}
```

## CORS permissions on S3 Bucket

Set-up a CORS configuration on the desired S3 Bucket

Permissions > CORS Configuration

Tip: {YOUR-ORG-ENDPOINT} must not end in /

Note: that if you are going to use it from a community or if you use a custom url you need to add a rule for it too

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CORSConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
    <CORSRule>
        <AllowedOrigin>{YOUR-ORG-ENDPOINT}</AllowedOrigin>
        <AllowedMethod>GET</AllowedMethod>
        <AllowedMethod>PUT</AllowedMethod>
        <AllowedMethod>POST</AllowedMethod>
        <AllowedMethod>DELETE</AllowedMethod>
        <AllowedHeader>*</AllowedHeader>
    </CORSRule>
</CORSConfiguration>
```

# Community Security Setting

In the Community Settings, under Security make sure the CSP is at least 

"Allow Inline Scripts and Script Access to Whitelisted Third-party Hosts"

## Set-up File Explorer component

Edit the record page of the desired object and include the File Explorer component.

### Connection Name

Name of the Connection Setting configured before (This allows to have different connection set-ups)

### Record Identifier

The field api name of the external identifier (Must be a unique field)

### Record Id (Community Builder ONLY)

Dynamically map the record id as per Community page param DEFAULT: {!recordId}

### Object Api Name (Community Builder ONLY)

Api name of the Object 

# Version History

### v0.0.1

- Initial Release
- AWS Interface
- S3 File Explorer
- Support for Community
