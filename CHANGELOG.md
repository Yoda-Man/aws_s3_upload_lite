## [0.1.7]
🚀 Major Improvements
1. Enhanced Error Handling
Added AwsS3UploadException class - Custom exception with detailed error information

Input validation - Validates required parameters before upload attempts

File validation - Checks if files exist and have content

HTTP status code handling - Properly handles success (200-299) and error status codes

Structured error propagation - Uses proper exception handling with rethrow

2. Improved Return Values
All methods now return full S3 URLs instead of just HTTP status codes

Better success feedback - Returns usable file URLs like https://bucket.s3.region.amazonaws.com/path/file.jpg

3. Code Optimization & Maintenance
Deprecated uploadUint8List - Marked as deprecated in favor of unified upload method

Reduced code duplication - uploadUint8List now delegates to upload internally

Better method organization - Clear separation between File and Uint8List uploads

4. New Features & Enhancements
Progress tracking - Added OnUploadProgressCallback for real-time upload monitoring

Session token support - Added support for AWS temporary credentials

Metadata handling - Proper AWS-compliant metadata parameter conversion

Custom headers - Support for additional HTTP headers

Flexible key management - Custom S3 key override option

📋 Detailed Changes
Before → After
Aspect	Before	After
Error Handling	Returned error strings	Throws AwsS3UploadException
Return Value	HTTP status code string	Full S3 file URL
Progress Tracking	Not available	onUploadProgress callback
Method Organization	Duplicate code in uploadUint8List	Unified upload method
Input Validation	Minimal validation	Comprehensive parameter checking
Session Tokens	Not supported	Full session token support
New Methods Added
_validateUploadParameters() - Validates required parameters

_handleResponse() - Processes HTTP responses

_buildFileUrl() - Constructs S3 file URLs

_convertMetadataToParams() - Formats metadata for AWS

Method Behavior Changes
uploadFile: Now returns S3 URL, throws exceptions, supports progress tracking

uploadUint8List: Now deprecated, delegates to upload, returns S3 URL

upload: Main method for Uint8List data, returns S3 URL, enhanced error handling

🛠 Technical Improvements
Error Handling
dart
// Before: Returned string
String result = await AwsS3.uploadFile(...);
if (result != "200") {
  print("Error: $result"); // Unclear error messages
}

// After: Structured exceptions
try {
  String url = await AwsS3.uploadFile(...);
  print("Success: $url");
} on AwsS3UploadException catch (e) {
  print("Error: ${e.message}"); // Clear, structured errors
}
Return Value Enhancement
dart
// Before: Just status code
String status = await AwsS3.uploadFile(...); // "200"

// After: Useful file URL
String fileUrl = await AwsS3.uploadFile(...); 
// "https://bucket.s3.region.amazonaws.com/uploads/file.jpg"
🎯 Benefits for Developers
1. Better Debugging
Clear, descriptive error messages

Structured exception hierarchy

HTTP status code information

Underlying error details

2. Enhanced Usability
Immediate access to uploaded file URLs

Progress tracking for large files

Flexible credential management

Comprehensive metadata support

3. Improved Reliability
Input validation prevents common errors

File existence checks

Proper AWS signature handling

Secure SSL enforcement

4. Future-Proofing
Deprecated method guidance

Consistent API patterns

Extensible exception system

Modern Flutter compatibility

📝 Migration Guide
For Existing Users
Update error handling - Switch from string checks to try-catch blocks

Use returned URLs - File URLs are now available immediately

Replace uploadUint8List - Use upload method instead

Leverage new features - Progress tracking, session tokens, etc.

Code Migration Example
dart
// OLD WAY
String status = await AwsS3.uploadUint8List(...);
if (status == "200") {
  print("Success");
} else {
  print("Error: $status");
}

// NEW WAY
try {
  String fileUrl = await AwsS3.upload(...);
  print("File available at: $fileUrl");
} on AwsS3UploadException catch (e) {
  print("Upload failed: ${e.message}");
}
🔧 Backward Compatibility
✅ All existing method signatures preserved

✅ Return type remains Future<String> (but now returns URLs)

✅ Parameter names unchanged

✅ Deprecated methods still functional (with warnings)

🚨 Breaking Changes
Error handling approach - Now uses exceptions instead of string returns

uploadUint8List deprecated - Will be removed in future versions

Return value meaning - Now returns URLs instead of status codes

## [0.1.6]
Updated dependencies.

## [0.1.5]
Add headers support and onProgress callback for other methods - 
dhikshithrm

Add support for sessionToken - chenqiongyao

## [0.1.4]
Upload with progress Documentation. Updated dependencies

## [0.1.3]
Change new upload method with upload progress

## [0.1.2]
Added new upload method with upload progress

## [0.1.1]
Increased upload time to cater for slow upload speeds

## [0.1.0]

Updated dependencies. Improved error handling

## [0.0.9]

Updated dependencies.

## [0.0.8]

Updated dependencies.

## [0.0.7] - 2/16/2024

Fixed Example.


## [0.0.6] - 2/16/2024

Added Example.

## [0.0.5] - 2/16/2024

Updated description in pubspec.yaml.

## [0.0.4] - 2/12/2024

Upload Uint8List has been added.

## [0.0.3] - 2/12/2024

Update upload instructions.

## [0.0.2] - 2/05/2024

Correcting Constraints 

## [0.0.1] - 2/05/2024

Initial Release