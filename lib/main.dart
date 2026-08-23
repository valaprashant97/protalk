import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'routes/routes.dart';
import 'services/database/database_helper.dart';
import 'services/theme/theme_service.dart';
import 'services/voice/text_to_speech.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await DatabaseHelper.instance.database;
  await ThemeService.to.init();
  await TextToSpeechService.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Professional Communication Simulator',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeService.to.themeMode,
        getPages: Routes.routes,
        initialRoute: AppRoutes.splash,
      );
    });
  }
}
