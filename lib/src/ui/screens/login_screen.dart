import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_mkey_app/src/notifiers/settings_notifier.dart';
import 'package:rhineix_mkey_app/src/services/auth_service.dart';
import 'package:rhineix_mkey_app/src/services/config_service.dart';
import 'package:rhineix_mkey_app/src/ui/widgets/app_snackbar.dart';
import 'package:rhineix_mkey_app/src/core/enums.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isFirstLaunch = false;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final configService = context.read<ConfigService>();
    final isFirst = await configService.checkIsFirstLaunch();
    if (mounted) {
      setState(() {
        _isFirstLaunch = isFirst;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);

    final authService = context.read<AuthService>();
    final settingsNotifier = context.read<SettingsNotifier>();
    final configService = context.read<ConfigService>();

    final result = await authService.signInWithEmailPassword(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (mounted) {
      if (result != null) {
        setState(() => _isLoading = false);
        showAppSnackBar(context,
            message: 'فشل تسجيل الدخول: $result',
            type: NotificationType.error);
      } else {
        // On success, save the name if it's the first launch
        if (_isFirstLaunch) {
          await settingsNotifier.saveGeneralConfig(
            currentUser: _nameController.text.trim(),
            activeCurrency: settingsNotifier.activeCurrency,
            exchangeRate: settingsNotifier.exchangeRate,
          );
          await configService.markFirstLaunchDone();
        }
        // The AuthWrapper will handle navigation automatically
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Symbols.key,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'MASTER KEY',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 32),
                if (_isFirstLaunch) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسمك (للسجلات)',
                      prefixIcon: Icon(Symbols.person),
                    ),
                    validator: (value) =>
                    (value?.trim().isEmpty ?? true) ? 'الرجاء إدخال اسمك' : null,
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    prefixIcon: Icon(Symbols.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => (value?.isEmpty ?? true)
                      ? 'الرجاء إدخال البريد الإلكتروني'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: const Icon(Symbols.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible
                          ? Symbols.visibility_off
                          : Symbols.visibility),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) =>
                  (value?.isEmpty ?? true) ? 'الرجاء إدخال كلمة المرور' : null,
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('تسجيل الدخول'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}