import 'dart:typed_data';

import 'package:aws_s3_upload_lite/aws_s3_upload_lite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('AwsS3', () {
    test('validation throws exception for missing keys', () {
      expect(
        () => AwsS3.upload(
            accessKey: '',
            secretKey: 's',
            bucket: 'b',
            region: 'r',
            filename: 'f',
            file: Uint8List(1),
            destDir: ''),
        throwsA(isA<AwsS3UploadException>()),
      );
    });

    test('upload success returns url', () async {
      final client = MockClient((request) async {
        return http.Response('', 200);
      });

      final url = await AwsS3.upload(
        accessKey: 'acc',
        secretKey: 'sec',
        bucket: 'bucket',
        region: 'region',
        filename: 'file.txt',
        file: Uint8List.fromList([1, 2, 3]),
        destDir: 'uploads',
        client: client,
      );

      expect(url, 'https://bucket.s3.region.amazonaws.com/uploads/file.txt');
    });

    test('upload failure throws exception', () async {
      final client = MockClient((request) async {
        return http.Response('Forbidden', 403);
      });

      expect(
        () => AwsS3.upload(
          accessKey: 'acc',
          secretKey: 'sec',
          bucket: 'bucket',
          region: 'region',
          filename: 'file.txt',
          file: Uint8List(1),
          destDir: '',
          client: client,
        ),
        throwsA(isA<AwsS3UploadException>()),
      );
    });
  });
}
