import 'package:file_picker/file_picker.dart';

Future<void> uploadMultipart({
  required String url,
  required Map<String, String> fields,
  required PlatformFile videoFile,
  required PlatformFile thumbnailFile,
  required List<PlatformFile> supportingDocs,
  required void Function(double progress) onProgress,
  required void Function(String responseBody, int statusCode) onComplete,
  required void Function(dynamic error) onError,
}) {
  throw UnsupportedError("Platform not supported");
}
