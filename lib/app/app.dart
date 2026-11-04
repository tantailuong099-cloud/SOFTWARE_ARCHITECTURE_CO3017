import 'package:flutter/material.dart';
import 'package:tmc_gate_app/app/router/app_router.dart';
import 'package:tmc_gate_app/app/theme/app_theme.dart';

class TMCGateApp extends StatelessWidget {
  const TMCGateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TMC Gate Station',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
