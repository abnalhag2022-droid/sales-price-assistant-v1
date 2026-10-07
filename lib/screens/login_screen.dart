import 'package:flutter/material.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  final AppController controller;
  const LoginScreen({super.key, required this.controller});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final user = TextEditingController(text: 'sales');
  final pass = TextEditingController();
  bool demo = const bool.fromEnvironment('DEMO_MODE', defaultValue: false);
  bool obscure = true;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('مساعد المبيعات', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.primary)),
                      const SizedBox(height: 5),
                      const Text('تسعير ومبيعات سريعة — النسخة الهاتفية V1'),
                      const SizedBox(height: 20),
                      TextField(controller: user, decoration: const InputDecoration(labelText: 'اسم المستخدم')),
                      const SizedBox(height: 10),
                      TextField(
                        controller: pass,
                        obscureText: obscure,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => obscure = !obscure),
                            icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: widget.controller.busy ? null : () async {
                          final ok = await widget.controller.login(user.text.trim(), pass.text, demo: demo);
                          if (!ok && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.controller.error ?? 'تعذر تسجيل الدخول')));
                          }
                        },
                        child: const Padding(padding: EdgeInsets.all(3), child: Text('دخول')),
                      ),
                      if (demo) ...[
                        const SizedBox(height: 8),
                        const Text('وضع التجربة المحلي مفعّل. استخدم sales أو admin دون كلمة مرور.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppTheme.muted)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
