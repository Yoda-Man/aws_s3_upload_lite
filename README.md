# aws_s3_upload_lite

[![pub package](https://img.shields.io/pub/v/aws_s3_upload_lite.svg)](https://pub.dev/packages/aws_s3_upload_lite)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A lightweight, well-maintained Flutter package for uploading files to AWS S3 buckets with ease. Provides simple APIs for uploading files, byte data, and monitoring upload progress.

> Inspired by `aws_s3_upload` - rebuilt for modern Flutter with enhanced error handling and better developer experience.

## Features

- ✅ Upload files from `File` objects or `Uint8List` data
- ✅ Progress tracking callbacks
- ✅ Custom metadata and headers support
- ✅ Flexible file path configuration
- ✅ ACL permissions management
- ✅ Enhanced error handling with descriptive exceptions
- ✅ Session token support for temporary credentials
- ✅ Returns full S3 URLs on successful uploads
- ✅ No external dependencies beyond AWS signature calculation

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  aws_s3_upload_lite: ^<latest-version>
```  

## Upload a File

Having created credentials on AWS, you can upload a file like this:

```dart
try {
  String fileUrl = await AwsS3.uploadFile(
    accessKey: 'your-access-key',
    secretKey: 'your-secret-key',
    bucket: 'your-bucket',
    file: File('path/to/your/file.jpg'),
    region: 'us-east-1',
    destDir: 'uploads',
    filename: 'photo.jpg',
  );
  
  print('File uploaded successfully: $fileUrl');
  // Output: File uploaded successfully: https://your-bucket.s3.us-east-1.amazonaws.com/uploads/photo.jpg
  
} catch (e) {
  print('Upload failed: $e');
}
```

Advanced Usage With Custom Metadata and Headers

```dart
String fileUrl = await AwsS3.uploadFile(
  accessKey: 'your-access-key',
  secretKey: 'your-secret-key',
  bucket: 'secure-bucket',
  file: documentFile,
  region: 'us-east-1',
  destDir: 'confidential',
  filename: 'contract.pdf',
  acl: ACL.private,
  contentType: 'application/pdf',
  metadata: {
    'department': 'legal',
    'document-type': 'contract',
    'confidential-level': 'high',
  },
  headers: {
    'Cache-Control': 'no-cache',
    'x-amz-server-side-encryption': 'AES256',
  },
  useSSL: true, // Force HTTPS
);
```


## API Reference

### AwsS3.uploadFile

Uploads a `File` object to S3.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `accessKey` | String | ✅ | AWS access key ID |
| `secretKey` | String | ✅ | AWS secret access key |
| `sessionToken` | String | ❌ | AWS session token for temporary credentials |
| `bucket` | String | ✅ | S3 bucket name |
| `file` | File | ✅ | File object to upload |
| `region` | String | ✅ | AWS region (e.g., 'us-east-1') |
| `destDir` | String | ✅ | Destination directory path |
| `filename` | String | ✅ | Target filename |
| `key` | String | ❌ | Custom S3 key (overrides destDir/filename) |
| `acl` | ACL | ❌ | Access control list (default: `ACL.public_read`) |
| `contentType` | String | ❌ | MIME type (default: 'binary/octet-stream') |
| `useSSL` | bool | ❌ | Use HTTPS (default: true) |
| `metadata` | Map<String, String> | ❌ | Additional file metadata |
| `headers` | Map<String, String> | ❌ | Additional HTTP headers |
| `onUploadProgress` | Function | ❌ | Progress callback: `(sentBytes, totalBytes)` |

**Returns:** `Future<String>` - The full S3 URL of the uploaded file

**Throws:** `AwsS3UploadException` on failure

**Example: with a onUploadProgress callback function to moniter upload progress **

```dart
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
**Debug Tips**

```dart
// Enable debug logging by wrapping in try-catch
try {
  String url = await AwsS3.uploadFile(...);
  print('Success: $url');
} catch (e) {
  print('Error details: $e');
  if (e is AwsS3UploadException) {
    print('Full error: ${e.toString()}');
  }
}
```
### AwsS3UploadException

Custom exception class for AWS S3 upload errors that provides detailed error information for better debugging and error handling.

**Properties:**

| Property | Type | Description |
|----------|------|-------------|
| `message` | String | Primary descriptive error message explaining what went wrong |
| `underlyingError` | String? | The original error message or stack trace that caused the exception |
| `statusCode` | String? | HTTP status code returned by AWS S3 (if available) |

**Methods:**

| Method | Returns | Description |
|--------|---------|-------------|
| `toString()` | String | Returns a formatted string representation of the exception |

**Common Error Scenarios:**

| Scenario | Exception Message Example |
|----------|--------------------------|
| Missing credentials | `AwsS3UploadException: Access key cannot be empty` |
| File not found | `AwsS3UploadException: File does not exist: /path/to/file.jpg` |
| Empty file data | `AwsS3UploadException: File content cannot be empty` |
| AWS permission denied | `AwsS3UploadException: Upload failed with HTTP status 403` |
| Bucket not found | `AwsS3UploadException: Upload failed with HTTP status 404` |
| Network issues | `AwsS3UploadException: Failed to upload file: photo.jpg` |

**Usage Example:**

```dart
try {
  String fileUrl = await AwsS3.uploadFile(
    accessKey: 'AKIA...',
    secretKey: 'secret...',
    bucket: 'my-bucket',
    file: File('path/to/file.jpg'),
    region: 'us-east-1',
    destDir: 'uploads',
    filename: 'photo.jpg',
  );
} on AwsS3UploadException catch (e) {
  // Handle specific S3 upload errors
  print('S3 Upload Failed: ${e.message}');
  
  if (e.underlyingError != null) {
    print('Technical details: ${e.underlyingError}');
  }
  
  if (e.statusCode != null) {
    print('HTTP Status: ${e.statusCode}');
    
    // Handle specific status codes
    if (e.statusCode == '403') {
      print('Check your AWS permissions and credentials');
    } else if (e.statusCode == '404') {
      print('Bucket or region may not exist');
    }
  }
} catch (e) {
  // Handle other types of exceptions
  print('Unexpected error: $e');
}
```

Contributing
Contributions are welcome! Please feel free to:

Fork the repository

Create a feature branch

Submit a Pull Request with tests

File issues for bugs or feature requests

License
This project is licensed under the MIT License - see the LICENSE file for details.

Support
If you encounter any problems or have suggestions, please file an issue on the GitHub repository.

Security Note: Always keep your AWS credentials secure. Never commit them to version control. Use environment variables, AWS Secrets Manager, or secure storage solutions.

Best Practice: Use IAM roles and temporary credentials in production environments instead of long-term access keys.