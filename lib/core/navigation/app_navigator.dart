import 'package:flutter/material.dart';

final appNavigatorKey = GlobalKey<NavigatorState>();

void popToRoot() {
  appNavigatorKey.currentState?.popUntil((route) => route.isFirst);
}
