import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../update_service.dart';

/// Web has no APK installer, so open the download link instead.
Future<void> runAppUpdater(BuildContext context, AppUpdate update) async {
  await launchUrl(
    Uri.parse(update.apkUrl),
    mode: LaunchMode.externalApplication,
  );
}