import 'dart:js_interop';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:web/web.dart' as web;

const int _maxBlobUrls = 16;
final List<String> _blobUrls = <String>[];

Future<({String url, Map<String, String>? headers})>
    resolvePlayableStreamUrl({
  required String url,
  required Map<String, String>? headers,
  required Dio dio,
}) async {
  if (headers == null || headers.isEmpty) {
    return (url: url, headers: headers);
  }

  final response = await dio.get<List<int>>(
    url,
    options: Options(responseType: ResponseType.bytes),
  );
  final data = response.data;
  if (data == null || data.isEmpty) {
    throw StateError('Empty audio payload for $url');
  }

  final bytes = data is Uint8List ? data : Uint8List.fromList(data);
  final blob = web.Blob([bytes.toJS].toJS);
  final objectUrl = web.URL.createObjectURL(blob);
  _registerBlobUrl(objectUrl);
  return (url: objectUrl, headers: null);
}

void _registerBlobUrl(String url) {
  _blobUrls.add(url);
  if (_blobUrls.length > _maxBlobUrls) {
    final oldest = _blobUrls.removeAt(0);
    web.URL.revokeObjectURL(oldest);
  }
}