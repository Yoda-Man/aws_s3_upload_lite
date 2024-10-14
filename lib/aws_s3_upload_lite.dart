library aws_s3_upload_lite;

import 'dart:async';
import 'dart:io';

import 'package:amazon_cognito_identity_dart_2/sig_v4.dart';
import 'package:flutter/foundation.dart';
import '../enum/acl.dart';
import '../src/utils.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';

import './src/policy.dart';
import 'src/multipart_request.dart';

typedef OnUploadProgressCallback = void Function(int sentBytes, int totalBytes);
late final void Function(int bytes, int totalBytes) onProgress;

/// Convenience class for uploading files to AWS S3
class AwsS3 {
  /// Upload a file, returning the status code 200/204 on success.
  static Future<String> uploadFile({
    /// AWS access key
    required String accessKey,

    /// AWS secret key
    required String secretKey,

    /// AWS session Token
    String? sessionToken,

    /// The name of the S3 storage bucket to upload  to
    required String bucket,

    /// The file to upload
    required File file,

    /// The AWS region. Must be formatted correctly, e.g. us-west-1
    required String region,

    /// The path to upload the file to (e.g. "uploads/public"). Defaults to the root "directory"
    required String destDir,

    /// The filename to upload as.
    required String filename,

    /// The key to save this file as. Will override destDir and filename if set.
    String? key,

    /// Access control list enables you to manage access to bucket and objects
    /// For more information visit [https://docs.aws.amazon.com/AmazonS3/latest/userguide/acl-overview.html]
    ACL acl = ACL.public_read,

    /// The content-type of file to upload. defaults to binary/octet-stream.
    String contentType = 'binary/octet-stream',

    /// If set to true, https is used instead of http. Default is true.
    bool useSSL = true,

    /// Additional metadata to be attached to the upload
    Map<String, String>? metadata,
  }) async {
    try {
      var httpStr = 'http';
      if (useSSL) {
        httpStr += 's';
      }
      final endpoint = '$httpStr://$bucket.s3.$region.amazonaws.com';

      String? uploadKey;

      if (key != null) {
        uploadKey = key;
      } else if (destDir.isNotEmpty) {
        uploadKey = '$destDir/$filename';
      } else {
        uploadKey = '$filename';
      }

      final stream = http.ByteStream(Stream.castFrom(file.openRead()));
      final length = await file.length();

      final uri = Uri.parse(endpoint);
      final req = http.MultipartRequest("POST", uri);
      final multipartFile = http.MultipartFile('file', stream, length,
          filename: path.basename(file.path));

      // Convert metadata to AWS-compliant params before generating the policy.
      final metadataParams = _convertMetadataToParams(metadata);

      // Generate pre-signed policy.
      final policy = Policy.fromS3PresignedPost(
        uploadKey,
        bucket,
        accessKey,
        45,
        length,
        acl,
        region: region,
        metadata: metadataParams,
      );

      final signingKey =
          SigV4.calculateSigningKey(secretKey, policy.datetime, region, 's3');
      final signature = SigV4.calculateSignature(signingKey, policy.encode());

      req.files.add(multipartFile);
      req.fields['key'] = policy.key;
      req.fields['acl'] = aclToString(acl);
      req.fields['X-Amz-Credential'] = policy.credential;
      req.fields['X-Amz-Algorithm'] = 'AWS4-HMAC-SHA256';
      req.fields['X-Amz-Date'] = policy.datetime;
      req.fields['Policy'] = policy.encode();
      req.fields['X-Amz-Signature'] = signature;
      req.fields['Content-Type'] = contentType;

      if(sessionToken != null){
        req.fields['X-Amz-Security-Token'] = sessionToken;
      }

      // If metadata isn't null, add metadata params to the request.
      if (metadata != null) {
        req.fields.addAll(metadataParams);
      }

      try {
        final res = await req.send();

        return res.statusCode.toString();
      } catch (e) {
        return e.toString();
      }
    } catch (e) {
      return e.toString();
    }
  }

  /// A method to transform the map keys into the format compliant with AWS.
  /// AWS requires that each metadata param be sent as `x-amz-meta-*`.
  static Map<String, String> _convertMetadataToParams(
      Map<String, String>? metadata) {
    Map<String, String> updatedMetadata = {};

    if (metadata != null) {
      for (var k in metadata.keys) {
        updatedMetadata['x-amz-meta-${k.paramCase}'] = metadata[k]!;
      }
    }

    return updatedMetadata;
  }

  /// Upload a Uint8List, returning the status code 200/204 on success.
  static Future<String> uploadUint8List({
    /// AWS access key
    required String accessKey,

    /// AWS secret key
    required String secretKey,

    /// AWS session Token
    String? sessionToken,

    /// The name of the S3 storage bucket to upload  to
    required String bucket,

    /// The file to upload
    required Uint8List file,

    /// The AWS region. Must be formatted correctly, e.g. us-west-1
    required String region,

    /// The path to upload the file to (e.g. "uploads/public"). Defaults to the root "directory"
    required String destDir,

    /// The filename to upload as.
    required String filename,

    /// The key to save this file as. Will override destDir and filename if set.
    String? key,

    /// Access control list enables you to manage access to bucket and objects
    /// For more information visit [https://docs.aws.amazon.com/AmazonS3/latest/userguide/acl-overview.html]
    ACL acl = ACL.public_read,

    /// The content-type of file to upload. defaults to binary/octet-stream.
    String contentType = 'binary/octet-stream',

    /// If set to true, https is used instead of http. Default is true.
    bool useSSL = true,

    /// Additional metadata to be attached to the upload
    Map<String, String>? metadata,
  }) async {
    try {
      var httpStr = 'http';
      if (useSSL) {
        httpStr += 's';
      }

      final endpoint = '$httpStr://$bucket.s3.$region.amazonaws.com';

      String? uploadKey;

      if (key != null) {
        uploadKey = key;
      } else if (destDir.isNotEmpty) {
        uploadKey = '$destDir/$filename';
      } else {
        uploadKey = '$filename';
      }

      final filestream = Stream.fromIterable(file.map((e) => [e]));

      final stream = http.ByteStream(filestream);
      final length = file.lengthInBytes;

      final uri = Uri.parse(endpoint);
      final req = http.MultipartRequest("POST", uri);
      final multipartFile =
          http.MultipartFile('file', stream, length, filename: filename);

      // Convert metadata to AWS-compliant params before generating the policy.
      final metadataParams = _convertMetadataToParams(metadata);

      // Generate pre-signed policy.
      final policy = Policy.fromS3PresignedPost(
        uploadKey,
        bucket,
        accessKey,
        45,
        length,
        acl,
        region: region,
        metadata: metadataParams,
      );

      final signingKey =
          SigV4.calculateSigningKey(secretKey, policy.datetime, region, 's3');
      final signature = SigV4.calculateSignature(signingKey, policy.encode());

      req.files.add(multipartFile);
      req.fields['key'] = policy.key;
      req.fields['acl'] = aclToString(acl);
      req.fields['X-Amz-Credential'] = policy.credential;
      req.fields['X-Amz-Algorithm'] = 'AWS4-HMAC-SHA256';
      req.fields['X-Amz-Date'] = policy.datetime;
      req.fields['Policy'] = policy.encode();
      req.fields['X-Amz-Signature'] = signature;
      req.fields['Content-Type'] = contentType;
      if(sessionToken != null){
        req.fields['X-Amz-Security-Token'] = sessionToken;
      }
      // If metadata isn't null, add metadata params to the request.
      if (metadata != null) {
        req.fields.addAll(metadataParams);
      }

      try {
        final res = await req.send();

        return res.statusCode.toString();
      } catch (e) {
        return e.toString();
      }
    } catch (e) {
      return e.toString();
    }
  }

  /// Upload a Uint8List with progress, returning the status code 200/204 on success.
  static Future<String> upload(
      {
      /// AWS access key
      required String accessKey,

      /// AWS secret key
      required String secretKey,

      /// AWS session Token
      String? sessionToken,

      /// The name of the S3 storage bucket to upload  to
      required String bucket,

      /// The file to upload
      required Uint8List file,

      /// The AWS region. Must be formatted correctly, e.g. us-west-1
      required String region,

      /// The path to upload the file to (e.g. "uploads/public"). Defaults to the root "directory"
      required String destDir,

      /// The filename to upload as.
      required String filename,

      /// The key to save this file as. Will override destDir and filename if set.
      String? key,

      /// Access control list enables you to manage access to bucket and objects
      /// For more information visit [https://docs.aws.amazon.com/AmazonS3/latest/userguide/acl-overview.html]
      ACL acl = ACL.public_read,

      /// The content-type of file to upload. defaults to binary/octet-stream.
      String contentType = 'binary/octet-stream',

      /// If set to true, https is used instead of http. Default is true.
      bool useSSL = true,

      /// Additional metadata to be attached to the upload
      Map<String, String>? metadata,

      /// On Upload Progress Callback Function
      required OnUploadProgressCallback? onUploadProgress}) async {
    try {
      var httpStr = 'http';
      if (useSSL) {
        httpStr += 's';
      }

      final endpoint = '$httpStr://$bucket.s3.$region.amazonaws.com';

      String? uploadKey;

      if (key != null) {
        uploadKey = key;
      } else if (destDir.isNotEmpty) {
        uploadKey = '$destDir/$filename';
      } else {
        uploadKey = '$filename';
      }

      final filestream = Stream.fromIterable(file.map((e) => [e]));

      final stream = http.ByteStream(filestream);
      final length = file.lengthInBytes;

      final uri = Uri.parse(endpoint);
      final req = MultipartRequest(
        "POST",
        uri,
        onProgress: (int bytes, int total) {
          final progress = bytes / total;
          print('progress: $progress ($bytes/$total)');
          if (onUploadProgress != null) {
            onUploadProgress(bytes, total);
            // CALL STATUS CALLBACK;
          }
        },
      );
      final multipartFile =
          http.MultipartFile('file', stream, length, filename: filename);

      // Convert metadata to AWS-compliant params before generating the policy.
      final metadataParams = _convertMetadataToParams(metadata);

      // Generate pre-signed policy.
      final policy = Policy.fromS3PresignedPost(
        uploadKey,
        bucket,
        accessKey,
        45,
        length,
        acl,
        region: region,
        metadata: metadataParams,
      );

      final signingKey =
          SigV4.calculateSigningKey(secretKey, policy.datetime, region, 's3');
      final signature = SigV4.calculateSignature(signingKey, policy.encode());

      req.files.add(multipartFile);
      req.fields['key'] = policy.key;
      req.fields['acl'] = aclToString(acl);
      req.fields['X-Amz-Credential'] = policy.credential;
      req.fields['X-Amz-Algorithm'] = 'AWS4-HMAC-SHA256';
      req.fields['X-Amz-Date'] = policy.datetime;
      req.fields['Policy'] = policy.encode();
      req.fields['X-Amz-Signature'] = signature;
      req.fields['Content-Type'] = contentType;

      if(sessionToken != null){
        req.fields['X-Amz-Security-Token'] = sessionToken;
      }

      // If metadata isn't null, add metadata params to the request.
      if (metadata != null) {
        req.fields.addAll(metadataParams);
      }

/*       int byteCount = 0;

      var totalByteLength = req.contentLength; */

      try {
        final res = await req.send();

/*         res.stream.transform(
          StreamTransformer.fromHandlers(
            handleData: (data, sink) {
              sink.add(data);

              byteCount += data.length;

              if (onUploadProgress != null) {
                onUploadProgress(byteCount, totalByteLength);
                // CALL STATUS CALLBACK;
              }
            },
            handleError: (error, stack, sink) {
              throw error;
            },
            handleDone: (sink) {
              sink.close();
              // UPLOAD DONE;
            },
          ),
        ); */

        return res.statusCode.toString();
      } catch (e) {
        return e.toString();
      }
    } catch (e) {
      return e.toString();
    }
  }
}
