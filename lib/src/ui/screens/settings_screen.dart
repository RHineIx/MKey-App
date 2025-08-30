import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_workshop_app/main.dart';
import 'package:rhineix_workshop_app/src/core/enums.dart';
import 'package:rhineix_workshop_app/src/services/github_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _repoController;
  late final TextEditingController _tokenController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final githubService = context.read<GithubService>();
    _usernameController = TextEditingController(text: githubService.username ?? '');
    _repoController = TextEditingController(text: githubService.repo ?? '');
    _tokenController = TextEditingController(text: githubService.token ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _repoController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });
      final githubService = context.read<GithubService>();
      try {
        await githubService.saveConfig(
          _usernameController.text.trim(),
          _repoController.text.trim(),
          _tokenController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حفظ الإعدادات بنجاح'), backgroundColor: Colors.green),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل حفظ الإعدادات: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() { _isLoading = false; });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeSettings = context.watch<ThemeSettingsNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('إعدادات المزامنة', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'اسم مستخدم GitHub', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'هذا الحقل مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _repoController,
                decoration: const InputDecoration(labelText: 'اسم المستودع (Repository)', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'هذا الحقل مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tokenController,
                decoration: const InputDecoration(labelText: 'مفتاح الوصول الشخصي (PAT)', border: OutlineInputBorder()),
                obscureText: true,
                validator: (value) => value!.isEmpty ? 'هذا الحقل مطلوب' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveSettings,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('حفظ إعدادات المزامنة'),
              ),
              const Divider(height: 40),

              Text('إعدادات المظهر', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),

              // Use initialValue instead of the deprecated value
              DropdownButtonFormField<AppFontWeight>(
                initialValue: themeSettings.fontWeight,
                decoration: const InputDecoration(
                  labelText: 'سماكة الخط',
                  border: OutlineInputBorder(),
                ),
                items: AppFontWeight.values.map((weight) {
                  return DropdownMenuItem(
                    value: weight,
                    child: Text(weight.displayName),
                  );
                }).toList(),
                onChanged: (AppFontWeight? newValue) {
                  if (newValue != null) {
                    themeSettings.setFontWeight(newValue);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}