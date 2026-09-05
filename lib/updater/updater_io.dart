import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_chen_updater/flutter_chen_updater.dart';
import 'package:url_launcher/url_launcher.dart';

import '../update_service.dart';

/// Triggers the in-app update flow. On Android this downloads the APK and
/// hands it to the system installer; elsewhere it just opens the APK link.
Future<void> runAppUpdater(BuildContext context, AppUpdate update) async {
  if (Platform.isAndroid) {
    final info = UpdateInfo(
      version: update.version,
      downloadUrl: update.apkUrl,
      description: update.description,
      fileSize: update.fileSize,
      isForceUpdate: update.force,
    );

    await Updater.checkAndUpdate(
      context,
      info,
      onAlreadyLatest: () {},
    );
    return;
  }

  // Desktop fallback: open the download link in the system browser.
  await launchUrl(
    Uri.parse(update.apkUrl),
    mode: LaunchMode.externalApplication,
  );
}