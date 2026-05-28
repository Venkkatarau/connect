import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

Future<void> uploadMultipart({
  required String url,
  required Map<String, String> fields,
  required PlatformFile videoFile,
  required PlatformFile thumbnailFile,
  required List<PlatformFile> supportingDocs,
  required void Function(double progress) onProgress,
  required void Function(String responseBody, int statusCode) onComplete,
  required void Function(dynamic error) onError,
}) async {
  try {
    final uri = Uri.parse(url);
    final request = MultipartRequestWithProgress(
      "POST",
      uri,
      onProgress: (bytesUploaded, totalBytes) {
        onProgress(bytesUploaded / totalBytes);
      },
    );

    fields.forEach((key, value) {
      request.fields[key] = value;
    });

    if (videoFile.path != null) {
      request.files.add(await http.MultipartFile.fromPath("files", videoFile.path!));
    }
    if (thumbnailFile.path != null) {
      request.files.add(await http.MultipartFile.fromPath("thubminalFile", thumbnailFile.path!));
    }
    for (var doc in supportingDocs) {
      if (doc.path != null) {
        request.files.add(await http.MultipartFile.fromPath("files", doc.path!));
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    onComplete(response.body, response.statusCode);
  } catch (e) {
    onError(e);
  }
}

class MultipartRequestWithProgress extends http.MultipartRequest {
  final void Function(int bytesUploaded, int totalBytes) onProgress;

  MultipartRequestWithProgress(
    String method,
    Uri url, {
    required this.onProgress,
  }) : super(method, url);

  @override
  http.ByteStream finalize() {
    final byteStream = super.finalize();
    final total = contentLength;
    int bytesUploaded = 0;

    final transformer = StreamTransformer<List<int>, List<int>>.fromHandlers(
      handleData: (data, sink) {
        bytesUploaded += data.length;
        onProgress(bytesUploaded, total);
        sink.add(data);
      },
    );

    return http.ByteStream(byteStream.transform(transformer));
  }
}
