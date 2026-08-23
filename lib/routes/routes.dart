import 'package:get/get.dart';
import '../bindings/app_bindings.dart';
import '../core/middleware/route_log_middleware.dart';
import '../screens/chat_screen.dart';
import '../screens/login_screen.dart';
import '../screens/module_selection_screen.dart';
import '../screens/review_screen.dart';
import '../screens/session_selection_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/splash_screen.dart';
import 'app_routes.dart';

class Routes {
  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
      middlewares: [RouteLogMiddleware()],
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: LoginBinding(),
      middlewares: [RouteLogMiddleware()],
    ),
    GetPage(
      name: AppRoutes.sessionSelection,
      page: () => const SessionSelectionScreen(),
      binding: SessionSelectionBinding(),
      middlewares: [RouteLogMiddleware()],
    ),
    GetPage(
      name: AppRoutes.moduleSelection,
      page: () => const ModuleSelectionScreen(),
      binding: ModuleSelectionBinding(),
      middlewares: [RouteLogMiddleware()],
    ),
    GetPage(
      name: AppRoutes.chat,
      page: () => const ChatScreen(),
      binding: ChatBinding(),
      middlewares: [RouteLogMiddleware()],
    ),
    GetPage(
      name: AppRoutes.review,
      page: () => const ReviewScreen(),
      binding: ReviewBinding(),
      middlewares: [RouteLogMiddleware()],
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsScreen(),
      binding: SettingsBinding(),
      middlewares: [RouteLogMiddleware()],
    ),
  ];
}
