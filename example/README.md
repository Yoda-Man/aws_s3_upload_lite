# Example of usage `aws_s3_upload_lite`

```dart

import 'dart:io';

import 'package:aws_s3_upload_lite/aws_s3_upload_lite.dart';
import 'package:flutter/material.dart';

void main() {
  uploadbyfile();
  uploadbyUint8List();
}

Future<void> uploadbyfile() async {
  String response = await AwsS3.uploadFile(
      accessKey: "AKxxxxxxxxxxxxx",
      secretKey: "xxxxxxxxxxxxxxxxxxxxxxxxxx",
      file: File("path_to_file"),
      bucket: "bucket_name",
      region: "us-east-2",
      destDir: "",
      filename: "x.png",
      metadata: {"test": "test"});

  debugPrint(response);
}

Future<void> uploadbyUint8List() async {
  String response = await AwsS3.uploadUint8List(
      accessKey: "AKxxxxxxxxxxxxx",
      secretKey: "xxxxxxxxxxxxxxxxxxxxxxxxxx",
      file: File("path_to_file").readAsBytesSync(),
      bucket: "bucket_name",
      region: "us-east-2",
      destDir: "",
      filename: "x.png",
      metadata: {"test": "test"});

  debugPrint(response);
}

//Upload with progress

 void setUploadProgress(int sentBytes, int totalBytes) {
    debugPrint(
        'Upload progress: ${progress.value} (${bytes.value}/${total.value})');
  }



  await AwsS3.upload(
  accessKey: "AKxxxxxxxxxxxxx",
  secretKey: "xxxxxxxxxxxxxxxxxxxxxxxxxx",
  file: fileBytes, //Uint8List fileBytes
  bucket: "bucket_name",
  region: "us-east-2",
  destDir: "", // The path to upload the file to (e.g. "uploads/public"). Defaults to the root "directory"
  filename: "x.png", //The filename to upload as
  metadata: {"test": "test"} // optional
  onUploadProgress: setUploadProgress);

```