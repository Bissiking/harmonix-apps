// device_files.dart
export 'device_files_native.dart'
    if (dart.library.js_interop) 'device_files_web.dart';
