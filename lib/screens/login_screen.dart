import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  bool _busy = false;
  Future<void> _signIn() async {
    setState(() => _busy = true);
    final error = await _auth.signInWithGoogle();
    // mounted ตรวจว่าหน้าจอยังอยู่หรือไม่
    // ป้องกันการเรียก setState หลังจากหน้าจอถูกปิดไปแล้ว
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/app_logo.png',
                        width: 176,
                        height: 176,
                        fit: BoxFit.cover,
                      ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                      'อร่อยง่าย ๆ ใน มมส',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                      'เลือกร้านโปรด สั่งเมนูที่ชอบ แล้วติดตามออร์เดอร์ได้ในแอปเดียว',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                      width: double.infinity,
                      child: _busy
                          ? const Center(child: CircularProgressIndicator())
                          : FilledButton.icon(
                              onPressed: _signIn,
                              icon: const Icon(Icons.login_rounded),
                              label: const Text('เข้าสู่ระบบด้วย Google'),
                            ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                      'เข้าสู่ระบบอย่างปลอดภัยด้วยบัญชี Google',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
