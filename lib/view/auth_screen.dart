// lib/view/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/auth_controller.dart';
import '../model/app_theme.dart';
import 'survey_screen.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLogin = true;

  // Login controllers
  final _loginEmailCtrl    = TextEditingController();
  final _loginPassCtrl     = TextEditingController();

  // Register controllers
  final _regNameCtrl       = TextEditingController();
  final _regEmailCtrl      = TextEditingController();
  final _regPassCtrl       = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _regNameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    super.dispose();
  }

  void _navigateToSurvey() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SurveyScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final auth      = ref.read(authControllerProvider.notifier);

    // Navigate on success
    ref.listen(authControllerProvider, (_, next) {
      if (next.isSuccess) _navigateToSurvey();
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage ?? 'Error'), backgroundColor: AppTheme.error),
        );
        auth.clearError();
      }
    });

    return Scaffold(
      // resizeToAvoidBottomInset keeps gradient full-height when keyboard opens
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                // Minimum height = full available viewport so gradient fills screen
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                const SizedBox(height: 48),
                // Logo
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppTheme.radiusLg,
                    boxShadow: AppTheme.elevatedShadow,
                  ),
                  child: const Center(child: Text('🌏', style: TextStyle(fontSize: 36))),
                ),
                const SizedBox(height: 14),
                const Text('ASEAN Nexus',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                const Text('Your MSME Growth Engine',
                    style: TextStyle(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 36),

                // Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppTheme.radiusXxl,
                    boxShadow: AppTheme.elevatedShadow,
                  ),
                  child: Column(
                    children: [
                      // Tabs
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: AppTheme.radiusMd,
                        ),
                        child: Row(
                          children: [
                            _tab('Sign In',   _isLogin,  () => setState(() => _isLogin = true)),
                            _tab('Register', !_isLogin,  () => setState(() => _isLogin = false)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Form
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _isLogin
                            ? _LoginForm(
                                key: const ValueKey('login'),
                                emailCtrl: _loginEmailCtrl,
                                passCtrl: _loginPassCtrl,
                                obscure: _obscurePassword,
                                onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                                onSubmit: () => auth.signIn(_loginEmailCtrl.text, _loginPassCtrl.text),
                                isLoading: authState.isLoading,
                              )
                            : _RegisterForm(
                                key: const ValueKey('register'),
                                nameCtrl: _regNameCtrl,
                                emailCtrl: _regEmailCtrl,
                                passCtrl: _regPassCtrl,
                                obscure: _obscurePassword,
                                onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                                onSubmit: () => auth.register(_regNameCtrl.text, _regEmailCtrl.text, _regPassCtrl.text),
                                isLoading: authState.isLoading,
                              ),
                      ),

                      const SizedBox(height: 16),
                      _Divider(),
                      const SizedBox(height: 16),

                      // Google Sign-In
                      _GoogleButton(
                        isLoading: authState.isLoading,
                        onTap: () => auth.signInWithGoogle(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                    ],
                  ), // Column
                ), // IntrinsicHeight
              ), // ConstrainedBox
            ), // SingleChildScrollView
          ), // LayoutBuilder
        ), // SafeArea
      ), // Container
    );
  }

  Widget _tab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: AppTheme.radiusSm,
            boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)] : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: active ? AppTheme.textPrimary : AppTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Login Form ───────────────────────────────────────────────────────────────

class _LoginForm extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final bool isLoading;

  const _LoginForm({
    super.key,
    required this.emailCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('EMAIL'),
        const SizedBox(height: 6),
        TextFormField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'you@business.com'),
        ),
        const SizedBox(height: 14),
        _label('PASSWORD'),
        const SizedBox(height: 6),
        TextFormField(
          controller: passCtrl,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: '••••••••',
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
              onPressed: onToggleObscure,
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: isLoading ? null : onSubmit,
            child: isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Sign In'),
          ),
        ),
      ],
    );
  }
}

// ─── Register Form ────────────────────────────────────────────────────────────

class _RegisterForm extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final bool isLoading;

  const _RegisterForm({
    super.key,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('FULL NAME'),
        const SizedBox(height: 6),
        TextFormField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'Ahmad Razif')),
        const SizedBox(height: 14),
        _label('EMAIL'),
        const SizedBox(height: 6),
        TextFormField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'you@business.com'),
        ),
        const SizedBox(height: 14),
        _label('PASSWORD'),
        const SizedBox(height: 6),
        TextFormField(
          controller: passCtrl,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: 'Create password (min 6 chars)',
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
              onPressed: onToggleObscure,
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: isLoading ? null : onSubmit,
            child: isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Create Account'),
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or continue with', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;

  const _GoogleButton({required this.onTap, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: isLoading ? null : onTap,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
          side: const BorderSide(color: AppTheme.border, width: 1.5),
        ),
        child: isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google G logo
                  SizedBox(
                    width: 20, height: 20,
                    child: CustomPaint(painter: _GoogleLogoPainter()),
                  ),
                  const SizedBox(width: 10),
                  const Text('Sign in with Google',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                ],
              ),
      ),
    );
  }
}

// Minimal Google "G" painter
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paths = <Color, String>{
      const Color(0xFF4285F4): 'M20 10.2c0-.6-.1-1.2-.2-1.8H10v3.4h5.6c-.2 1.2-.9 2.2-2 2.9v2.4h3.2c1.9-1.7 3-4.3 3-6.9z',
    };
    // Simplified: draw a colourful arc
    final paint = Paint()..style = PaintingStyle.fill;
    final r = size.width / 2;
    const colors = [Color(0xFF4285F4), Color(0xFF34A853), Color(0xFFFBBC05), Color(0xFFEA4335)];
    for (int i = 0; i < 4; i++) {
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: Offset(r, r), radius: r),
        (i * 90 - 45) * 3.14159 / 180,
        90 * 3.14159 / 180,
        true,
        paint,
      );
    }
    // White center
    paint.color = Colors.white;
    canvas.drawCircle(Offset(r, r), r * 0.55, paint);
    // Blue "G"
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(Rect.fromLTWH(r, r - 2, r * 0.8, 4), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// Helper
Widget _label(String text) => Text(text,
    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 0.5));