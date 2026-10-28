import 'web_app_install_stub.dart'
    if (dart.library.js_interop) 'web_app_install_web.dart' as platform;

bool get canPromptToInstall => platform.canPromptToInstall;
bool get isRunningAsInstalledApp => platform.isRunningAsInstalledApp;
Future<bool> promptToInstall() => platform.promptToInstall();
