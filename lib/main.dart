import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/bucket_repository.dart';
import 'state/bucket_controller.dart';
import 'theme.dart';
import 'ui/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await LocalBucketRepository.open();
  final controller = BucketController(repository)..load();
  runApp(UsTimeApp(controller: controller));
}

class UsTimeApp extends StatelessWidget {
  const UsTimeApp({super.key, required this.controller});

  final BucketController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Us Time',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: HomePage(controller: controller),
    );
  }
}
