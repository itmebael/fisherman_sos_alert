import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants/colors.dart';
import 'constants/routes.dart';
import 'providers/auth_provider.dart';

class BantayDagatApp extends StatelessWidget {
  const BantayDagatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salbar Mangirisda',
      theme: ThemeData(
        primarySwatch: AppColors.primarySwatch,
        fontFamily: 'Roboto',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Initialize auth listener when app starts
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          authProvider.initializeAuthListener();
        });
        return child!;
      },
    );
  }
}