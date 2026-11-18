import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import 'app.dart';
import 'data/providers.dart';
import 'services/home_widget_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF181B22),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final notifications = NotificationService();
  await notifications.init();

  try {
    await HomeWidget.registerInteractivityCallback(
      homeWidgetInteractivityCallback,
    );
  } catch (e) {
    debugPrint('Registrasi callback widget gagal: $e');
  }

  runApp(
    ProviderScope(
      overrides: [notificationServiceProvider.overrideWithValue(notifications)],
      child: const MomentumApp(),
    ),
  );
}
