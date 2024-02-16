# aws_s3_upload_lite

Amazon S3 is an object storage service that stores data as objects within buckets. An object is a file and any metadata that describes the file. aws_s3_upload_lite is a simple, convenient package for uploading files to AWS S3 buckets.

Inspired by aws_s3_upload

## Getting Started

Having created credentials on AWS, you can upload a file like this:

```dart
AwsS3.uploadFile(
  accessKey: "AKxxxxxxxxxxxxx",
  secretKey: "xxxxxxxxxxxxxxxxxxxxxxxxxx",
  file: File("path_to_file"),
  bucket: "bucket_name",
  region: "us-east-2",
  destDir: "", // The path to upload the file to (e.g. "uploads/public"). Defaults to the root "directory"
  filename: "x.png", //The filename to upload as
  metadata: {"test": "test"} // optional
);
```

or 

```dart
AwsS3.uploadUint8List(
  accessKey: "AKxxxxxxxxxxxxx",
  secretKey: "xxxxxxxxxxxxxxxxxxxxxxxxxx",
  file: fileBytes, //Uint8List fileBytes
  bucket: "bucket_name",
  region: "us-east-2",
  destDir: "", // The path to upload the file to (e.g. "uploads/public"). Defaults to the root "directory"
  filename: "x.png", //The filename to upload as
  metadata: {"test": "test"} // optional
);
```

## Motivation

There are several Flutter plugins for interacting with AWS S3, this small library was built because the other packages are no longer well maintained.
