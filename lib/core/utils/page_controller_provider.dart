import 'package:flutter/material.dart';

mixin PageControllerMixin<T extends StatefulWidget> on State<T> {
  late final PageController pageController;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
