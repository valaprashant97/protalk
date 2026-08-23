import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../controllers/login_controller.dart';
import '../controllers/module_selection_controller.dart';
import '../controllers/review_controller.dart';
import '../controllers/session_selection_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SplashController>(() => SplashController());
  }
}

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(() => LoginController());
  }
}

class SessionSelectionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SessionSelectionController>(() => SessionSelectionController());
  }
}

class ModuleSelectionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ModuleSelectionController>(() => ModuleSelectionController());
  }
}

class ChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatController>(() => ChatController());
  }
}

class ReviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReviewController>(() => ReviewController());
  }
}

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingsController>(() => SettingsController());
  }
}
