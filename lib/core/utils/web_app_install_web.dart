// ignore: deprecated_member_use
import 'dart:html' as html;
import 'dart:js_util' as js_util;

html.Event? get _installEvent =>
    js_util.getProperty<html.Event?>(html.window, '__deferredInstallPrompt');

bool get canPromptToInstall => _installEvent != null;

bool get isRunningAsInstalledApp =>
    html.window.matchMedia('(display-mode: standalone)').matches ||
    js_util.getProperty(html.window.navigator, 'standalone') == true;

Future<bool> promptToInstall() async {
  final event = _installEvent;
  if (event == null) return false;
  js_util.setProperty(html.window, '__deferredInstallPrompt', null);
  await js_util.promiseToFuture<Object?>(js_util.callMethod(event, 'prompt', []));
  final choice = await js_util.promiseToFuture<Object?>(
    js_util.getProperty(event, 'userChoice'),
  );
  return js_util.getProperty(choice, 'outcome') == 'accepted';
}
