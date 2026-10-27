// sso_browser_web.dart
import 'package:web/web.dart' as web;

web.Window? _popup;
void prepareSsoBrowser() {
  // Open within the user gesture, before awaiting the SSO start request.
  _popup = web.window.open('about:blank', 'harmonix_sso');
}

Future<void> openSsoBrowser(Uri uri) async {
  if (_popup == null) {
    throw StateError('Autorise les fenêtres de connexion dans le navigateur.');
  }
  _popup!.location.href = uri.toString();
}

Future<void> finishSsoBrowser() async {
  _popup?.close();
  _popup = null;
  web.window.focus();
}
