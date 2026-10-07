import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'state/app_controller.dart';
import 'screens/login_screen.dart';
import 'screens/shell_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar_YE');
  final controller = AppController();
  await controller.bootstrap();
  runApp(SalesPriceAssistantApp(controller: controller));
}

class SalesPriceAssistantApp extends StatelessWidget {
  final AppController controller;
  const SalesPriceAssistantApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'مساعد المبيعات',
        theme: AppTheme.light,
        locale: const Locale('ar', 'YE'),
        supportedLocales: const [Locale('ar', 'YE'), Locale('en', 'US')],
        home: controller.isLoggedIn
            ? ShellScreen(controller: controller)
            : LoginScreen(controller: controller),
      ),
    );
  }
}
