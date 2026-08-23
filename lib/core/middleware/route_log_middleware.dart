import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RouteLogMiddleware extends GetMiddleware {
  @override
  int? get priority => 2;

  @override
  GetPage? onPageCalled(GetPage? page) {
    if (kDebugMode) {
      debugPrint('[GetX Navigation] Navigating to: ${page?.name}');
    }
    return super.onPageCalled(page);
  }

  @override
  Widget onPageBuilt(Widget page) {
    if (kDebugMode) {
      debugPrint('[GetX Navigation] Page Built: ${page.runtimeType}');
    }
    return super.onPageBuilt(page);
  }

  @override
  void onPageDispose() {
    if (kDebugMode) {
      debugPrint('[GetX Navigation] Page Disposed');
    }
    super.onPageDispose();
  }
}
