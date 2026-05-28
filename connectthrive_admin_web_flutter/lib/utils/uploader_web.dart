import 'dart:async';
import 'dart:html' as html;
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
}) async {
  try {
    final xhr = html.HttpRequest();
    xhr.open("POST", url);

    final formData = html.FormData();
    fields.forEach((key, value) {
      formData.append(key, value);
    });

    if (videoFile.bytes != null) {
      formData.appendBlob("files", html.Blob([videoFile.bytes!], 'video/mp4'), videoFile.name);
    }
    if (thumbnailFile.bytes != null) {
      formData.appendBlob("thubminalFile", html.Blob([thumbnailFile.bytes!], 'image/png'), thumbnailFile.name);
    }
    for (var doc in supportingDocs) {
      if (doc.bytes != null) {
        formData.appendBlob("files", html.Blob([doc.bytes!]), doc.name);
      }
    }

    xhr.upload.onProgress.listen((html.ProgressEvent event) {
      if (event.lengthComputable) {
        final progress = event.loaded! / event.total!;
        onProgress(progress);
      }
    });

    final completer = Completer<html.HttpRequest>();
    xhr.onLoad.listen((_) => completer.complete(xhr));
    xhr.onError.listen((e) => completer.completeError(e));

    xhr.send(formData);
    final responseXhr = await completer.future;

    onComplete(responseXhr.responseText ?? "", responseXhr.status ?? 500);
  } catch (e) {
    onError(e);
  }
}
