import 'package:in_app_update/in_app_update.dart';

void checkForUpdate() async {
  final updateInfo = await InAppUpdate.checkForUpdate();

  if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
    await InAppUpdate.performImmediateUpdate();
  }
}