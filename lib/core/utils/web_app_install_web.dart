import 'dart:js_interop';

@JS('canPromptToInstall')
external JSBoolean _canPromptToInstall();

@JS('isRunningAsInstalledApp')
external JSBoolean _isRunningAsInstalledApp();

@JS('promptToInstall')
external JSPromise<JSBoolean> _promptToInstall();

bool get canPromptToInstall => _canPromptToInstall().toDart;

bool get isRunningAsInstalledApp => _isRunningAsInstalledApp().toDart;

Future<bool> promptToInstall() async =>
    (await _promptToInstall().toDart).toDart;
