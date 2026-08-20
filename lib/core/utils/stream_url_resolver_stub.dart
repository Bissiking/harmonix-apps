import 'package:dio/dio.dart';

Future<({String url, Map<String, String>? headers})>
    resolvePlayableStreamUrl({
  required String url,
  required Map<String, String>? headers,
  required Dio dio,
}) async {
  return (url: url, headers: headers);
}

void revokeBlobUrl(String url) {}