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

/// Custom exception class for AWS S3 upload errors
class AwsS3UploadException implements Exception {
  final String message;
  final String? underlyingError;
  final String? statusCode;

  AwsS3UploadException(
      {required this.message, this.underlyingError, this.statusCode});

  @override
  String toString() {
    if (underlyingError != null) {
      return 'AwsS3UploadException: $message. Underlying error: $underlyingError';
    }
    return 'AwsS3UploadException: $message';
  }
}

/// Convenience class for uploading files to AWS S3
class AwsS3 {
  /// Validates required parameters before upload
  static void _validateUploadParameters({
    required String accessKey,
    required String secretKey,
    required String bucket,
    required String region,
    required String filename,
  }) {
    if (accessKey.isEmpty) {
      throw AwsS3UploadException(message: 'Access key cannot be empty');
    }
    if (secretKey.isEmpty) {
      throw AwsS3UploadException(message: 'Secret key cannot be empty');
    }
    if (bucket.isEmpty) {
      throw AwsS3UploadException(message: 'Bucket name cannot be empty');
    }
    if (region.isEmpty) {
      throw AwsS3UploadException(message: 'Region cannot be empty');
    }
    if (filename.isEmpty) {
      throw AwsS3UploadException(message: 'Filename cannot be empty');
    }
  }

  /// Handles HTTP response and throws appropriate exceptions
  static String _handleResponse(
      http.StreamedResponse response, String fileUrl) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Success status codes (200-299) - return the file URL
      return fileUrl;
    } else {
      throw AwsS3UploadException(
        message: 'Upload failed with HTTP status ${response.statusCode}',
        statusCode: response.statusCode.toString(),
      );
    }
  }

  /// Builds the S3 file URL from components
  static String _buildFileUrl({
    required String bucket,
    required String region,
    required bool useSSL,
    required String uploadKey,
  }) {
    var httpStr = 'http';
    if (useSSL) {
      httpStr += 's';
    }

    // Construct the full S3 URL for the uploaded file
    return '$httpStr://$bucket.s3.$region.amazonaws.com/$uploadKey';
  }

  /// Upload a file, returning the full S3 file URL on success.
  static Future<String> uploadFile({
    /// AWS access key
    required String accessKey,

    /// AWS secret key
    required String secretKey,

    /// AWS session Token
    String? sessionToken,

    /// The name of the S3 storage bucket to upload to
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

    /// Additional headers to be attached to the upload
    Map<String, String>? headers,

    /// On Upload Progress Callback Function
    final OnUploadProgressCallback? onUploadProgress,
  }) async {
    try {
      // Validate input parameters
      _validateUploadParameters(
        accessKey: accessKey,
        secretKey: secretKey,
        bucket: bucket,
        region: region,
        filename: filename,
      );

      // Check if file exists and is accessible
      if (!await file.exists()) {
        throw AwsS3UploadException(
            message: 'File does not exist: ${file.path}');
      }

      String? uploadKey;

      if (key != null) {
        uploadKey = key;
      } else if (destDir.isNotEmpty) {
        uploadKey = '$destDir/$filename';
      } else {
        uploadKey = '$filename';
      }

      // Build the file URL that will be returned on success
      final fileUrl = _buildFileUrl(
        bucket: bucket,
        region: region,
        useSSL: useSSL,
        uploadKey: uploadKey,
      );

      final endpoint = fileUrl.split('/').sublist(0, 3).join('/');
      final stream = http.ByteStream(Stream.castFrom(file.openRead()));
      final length = await file.length();

      final uri = Uri.parse(endpoint);
      final req = MultipartRequest("POST", uri, onProgress: onUploadProgress);
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

      if (sessionToken != null) {
        req.fields['X-Amz-Security-Token'] = sessionToken;
      }

      // If metadata isn't null, add metadata params to the request.
      if (metadata != null) {
        req.fields.addAll(metadataParams);
      }

      // If headers isn't null, add headers to the request.
      if (headers != null) {
        req.headers.addAll(headers);
      }

      final res = await req.send();
      return _handleResponse(res, fileUrl);
    } catch (e) {
      if (e is AwsS3UploadException) {
        rethrow;
      }
      throw AwsS3UploadException(
        message: 'Failed to upload file: $filename',
        underlyingError: e.toString(),
      );
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

  /// Upload a Uint8List, returning the full S3 file URL on success.
  ///
  /// @deprecated Use [upload] instead. This method will be removed in a future version.
  @Deprecated(
      'Use AwsS3.upload instead. This method will be removed in a future version.')
  static Future<String> uploadUint8List({
    /// AWS access key
    required String accessKey,

    /// AWS secret key
    required String secretKey,

    /// AWS session Token
    String? sessionToken,

    /// The name of the S3 storage bucket to upload to
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

    /// Additional headers to be attached to the upload
    Map<String, String>? headers,

    /// On Upload Progress Callback Function
    final OnUploadProgressCallback? onUploadProgress,
  }) async {
    // Delegate to the upload method to avoid code duplication
    return upload(
      accessKey: accessKey,
      secretKey: secretKey,
      sessionToken: sessionToken,
      bucket: bucket,
      file: file,
      region: region,
      destDir: destDir,
      filename: filename,
      key: key,
      acl: acl,
      contentType: contentType,
      useSSL: useSSL,
      metadata: metadata,
      headers: headers,
      onUploadProgress: onUploadProgress,
    );
  }

  /// Upload a Uint8List with progress, returning the full S3 file URL on success.
  static Future<String> upload({
    /// AWS access key
    required String accessKey,

    /// AWS secret key
    required String secretKey,

    /// AWS session Token
    String? sessionToken,

    /// The name of the S3 storage bucket to upload to
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

    /// Additional headers to be attached to the upload
    Map<String, String>? headers,

    /// On Upload Progress Callback Function
    final OnUploadProgressCallback? onUploadProgress,
  }) async {
    try {
      // Validate input parameters
      _validateUploadParameters(
        accessKey: accessKey,
        secretKey: secretKey,
        bucket: bucket,
        region: region,
        filename: filename,
      );

      // Validate file content
      if (file.isEmpty) {
        throw AwsS3UploadException(message: 'File content cannot be empty');
      }

      String? uploadKey;

      if (key != null) {
        uploadKey = key;
      } else if (destDir.isNotEmpty) {
        uploadKey = '$destDir/$filename';
      } else {
        uploadKey = '$filename';
      }

      // Build the file URL that will be returned on success
      final fileUrl = _buildFileUrl(
        bucket: bucket,
        region: region,
        useSSL: useSSL,
        uploadKey: uploadKey,
      );

      final endpoint = fileUrl.split('/').sublist(0, 3).join('/');
      final filestream = Stream.fromIterable(file.map((e) => [e]));
      final stream = http.ByteStream(filestream);
      final length = file.lengthInBytes;

      final uri = Uri.parse(endpoint);
      final req = MultipartRequest(
        "POST",
        uri,
        onProgress: onUploadProgress,
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

      if (sessionToken != null) {
        req.fields['X-Amz-Security-Token'] = sessionToken;
      }

      // If metadata isn't null, add metadata params to the request.
      if (metadata != null) {
        req.fields.addAll(metadataParams);
      }

      // If headers isn't null, add headers to the request.
      if (headers != null) {
        req.headers.addAll(headers);
      }

      final res = await req.send();
      return _handleResponse(res, fileUrl);
    } catch (e) {
      if (e is AwsS3UploadException) {
        rethrow;
      }
      throw AwsS3UploadException(
        message: 'Failed to upload: $filename',
        underlyingError: e.toString(),
      );
    }
  }
}
