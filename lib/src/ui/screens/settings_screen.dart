import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_mkey_app/src/core/custom_cache_manager.dart';
import 'package:rhineix_mkey_app/src/core/enums.dart';
import 'package:rhineix_mkey_app/src/models/github_file_model.dart';
import 'package:rhineix_mkey_app/src/notifiers/inventory_notifier.dart';
import 'package:rhineix_mkey_app/src/notifiers/settings_notifier.dart';
import 'package:rhineix_mkey_app/src/services/auth_service.dart';
import 'package:rhineix_mkey_app/src/ui/widgets/app_snackbar.dart';
import 'package:rhineix_mkey_app/src/ui/widgets/confirmation_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          _GeneralSettingsCard(),
          SizedBox(height: 16),
          _DataManagementCard(),
          SizedBox(height: 16),
          _AccountCard(),
        ],
      ),
    );
  }
}

class _GeneralSettingsCard extends StatefulWidget {
  const _GeneralSettingsCard();

  @override
  State<_GeneralSettingsCard> createState() => _GeneralSettingsCardState();
}

class _GeneralSettingsCardState extends State<_GeneralSettingsCard> {
  late final TextEditingController _userController;
  late final TextEditingController _exchangeRateController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsNotifier>();
    _userController = TextEditingController(text: settings.currentUser);
    _exchangeRateController =
        TextEditingController(text: settings.exchangeRate.toString());
  }

  @override
  void dispose() {
    _userController.dispose();
    _exchangeRateController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final settings = context.read<SettingsNotifier>();
    settings.saveGeneralConfig(
      currentUser: _userController.text,
      activeCurrency: settings.activeCurrency,
      exchangeRate: double.tryParse(_exchangeRateController.text) ?? 1460.0,
    );
    showAppSnackBar(context,
        message: 'تم حفظ الإعدادات العامة', type: NotificationType.success);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsNotifier>();
    final fontWeightMap = {
      AppFontWeight.light: 0.0,
      AppFontWeight.normal: 1.0,
      AppFontWeight.medium: 2.0,
      AppFontWeight.bold: 3.0,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('عام', style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            ListTile(
              title: const Text('المظهر'),
              trailing: SegmentedButton<AppThemeMode>(
                segments: AppThemeMode.values.map((mode) {
                  return ButtonSegment<AppThemeMode>(
                    value: mode,
                    label: Text(mode.displayName),
                  );
                }).toList(),
                selected: {settings.appThemeMode},
                onSelectionChanged: (Set<AppThemeMode> newSelection) {
                  settings.setAppThemeMode(newSelection.first);
                },
              ),
            ),
            const ListTile(title: Text('سماكة الخط')),
            Slider(
              value: fontWeightMap[settings.fontWeight]!,
              min: 0,
              max: 3,
              divisions: 3,
              label: settings.fontWeight.displayName,
              onChanged: (double value) {
                final newWeight = fontWeightMap.entries
                    .firstWhere((entry) => entry.value == value)
                    .key;
                settings.setFontWeight(newWeight);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _userController,
              decoration: const InputDecoration(labelText: 'اسم المستخدم (للسجلات)'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _exchangeRateController,
              decoration: const InputDecoration(labelText: 'سعر صرف الدولار'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('حفظ الإعدادات العامة'),
            )
          ],
        ),
      ),
    );
  }
}

class _DataManagementCard extends StatelessWidget {
  const _DataManagementCard();

  void _handleImageCleanup(BuildContext context) async {
    final inventoryNotifier = context.read<InventoryNotifier>();
    final List<GithubFile> unusedImages =
    await inventoryNotifier.findUnusedImages();

    if (!context.mounted) return;
    if (unusedImages.isEmpty) {
      showAppSnackBar(context,
          message: 'لا توجد صور غير مستخدمة ليتم حذفها.',
          type: NotificationType.info);
      return;
    }

    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'تأكيد الحذف',
      content:
      'تم العثور على ${unusedImages.length} صورة غير مستخدمة. هل تريد حذفها نهائياً من المستودع؟',
      confirmText: 'نعم، حذف ${unusedImages.length} صورة',
      icon: Symbols.delete_forever,
      isDestructive: true,
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final deletedCount =
      await inventoryNotifier.deleteUnusedImages(unusedImages);
      if (!context.mounted) return;
      showAppSnackBar(context,
          message: 'اكتمل التنظيف. تم حذف $deletedCount صورة بنجاح.',
          type: NotificationType.success);
    } catch (e) {
      if (!context.mounted) return;
      showAppSnackBar(context,
          message: 'فشل حذف الصور: $e', type: NotificationType.error);
    }
  }

  void _handleImageCacheClear(BuildContext context) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'تأكيد حذف الصور المؤقتة',
      content:
      'سيتم حذف جميع الصور المحفوظة على هذا الجهاز. سيتم إعادة تحميلها عند الحاجة. هل أنت متأكد؟',
      confirmText: 'نعم, حذف',
      icon: Symbols.delete,
      isDestructive: true,
    );
    if (confirmed != true || !context.mounted) return;
    try {
      showAppSnackBar(context,
          message: 'جاري حذف الصور...', type: NotificationType.syncing);
      await CustomCacheManager.clearCache();
      if (context.mounted) {
        showAppSnackBar(context,
            message: 'تم حذف الصور المحفوظة بنجاح.',
            type: NotificationType.success);
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context,
            message: 'فشل حذف الصور: $e', type: NotificationType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('إدارة البيانات', style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            // FIXED: Removed the archive browser list tile
            ListTile(
              leading: const Icon(Icons.cleaning_services_outlined),
              title: const Text('تنظيف الصور غير المستخدمة'),
              subtitle:
              const Text('حذف الصور من المستودع التي لا ترتبط بمنتج'),
              onTap: () => _handleImageCleanup(context),
            ),
            ListTile(
              leading: const Icon(Symbols.cached),
              title: const Text('تنظيف ذاكرة التخزين المؤقت للصور'),
              subtitle: const Text(
                  'حذف الصور المحفوظة على هذا الجهاز لتوفير مساحة'),
              onTap: () => _handleImageCacheClear(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard();

  void _signOut(BuildContext context) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'تسجيل الخروج',
      content: 'هل أنت متأكد من رغبتك في تسجيل الخروج؟',
      confirmText: 'خروج',
      icon: Symbols.logout,
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthService>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('الحساب', style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            ListTile(
              leading: const Icon(Symbols.person),
              title: const Text('المستخدم الحالي'),
              subtitle: Text(user?.email ?? 'غير مسجل'),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _signOut(context),
              icon: const Icon(Symbols.logout),
              label: const Text('تسجيل الخروج'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            )
          ],
        ),
      ),
    );
  }
}