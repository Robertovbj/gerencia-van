import 'package:flutter/material.dart';

class MainScaffoldKey extends InheritedWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const MainScaffoldKey({
    super.key,
    required this.scaffoldKey,
    required super.child,
  });

  static GlobalKey<ScaffoldState>? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<MainScaffoldKey>()
        ?.scaffoldKey;
  }

  @override
  bool updateShouldNotify(MainScaffoldKey oldWidget) => false;
}
