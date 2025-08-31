// FILE: lib/src/ui/screens/settings_screen.dart
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_mkey_app/src/core/enums.dart';
import 'package:rhineix_mkey_app/src/models/github_file_model.dart';
import 'package:rhineix_mkey_app/src/notifiers/activity_log_notifier.dart';
import 'package:rhineix_mkey_app/src/notifiers/dashboard_notifier.dart';
import 'package:rhineix_mkey_app/src/notifiers/inventory_notifier.dart';
import 'package:rhineix_mkey_app/src/notifiers/settings_notifier.dart';
import 'package:rhineix_mkey_app/src/notifiers/supplier_notifier.dart';
import 'package:rhineix_mkey_app/src/services/backup_service.dart';
import 'package:rhineix_mkey_app/src/services/github_service.dart';
import 'package:rhineix_mkey_app/src/ui/widgets/app_snackbar.dart';
import 'package:rhineix_mkey_app/src/ui/widgets/confirmation_dialog.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'عامة', icon: Icon(Icons.tune)),
            Tab(text: 'المزامنة', icon: Icon(Icons.cloud_sync)),
            Tab(text: 'البيانات', icon: Icon(Icons.storage)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _GeneralSettingsTab(),
          _SyncSettingsTab(),
          _DataManagementTab(),
        ],
      ),
    );
  }
}

// --- Tabs ---

class _GeneralSettingsTab extends StatefulWidget {
  const _GeneralSettingsTab();

  @override
  State<_GeneralSettingsTab> createState() => _GeneralSettingsTabState();
}

class _GeneralSettingsTabState extends State<_GeneralSettingsTab> {
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('المظهر', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        SegmentedButton<AppThemeMode>(
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
        const SizedBox(height: 24),
        Text('سماكة الخط', style: Theme.of(context).textTheme.titleLarge),
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
        const SizedBox(height: 24),
        Text('إعدادات المستخدم', style: Theme.of(context).textTheme.titleLarge),
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
    );
  }
}

class _SyncSettingsTab extends StatefulWidget {
  const _SyncSettingsTab();
  @override
  State<_SyncSettingsTab> createState() => _SyncSettingsTabState();
}

class _SyncSettingsTabState extends State<_SyncSettingsTab> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _repoController;
  late final TextEditingController _tokenController;

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
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final githubService = context.read<GithubService>();
    await githubService.saveConfig(
      _usernameController.text.trim(),
      _repoController.text.trim(),
      _tokenController.text.trim(),
    );
    if (!mounted) return;

    showAppSnackBar(context,
        message: 'تم حفظ إعدادات المزامنة', type: NotificationType.success);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'اسم مستخدم GitHub'),
            validator: (v) => v!.isEmpty ? 'هذا الحقل مطلوب' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _repoController,
            decoration:
                const InputDecoration(labelText: 'اسم المستودع (Repository)'),
            validator: (v) => v!.isEmpty ? 'هذا الحقل مطلوب' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _tokenController,
            decoration:
                const InputDecoration(labelText: 'مفتاح الوصول الشخصي (PAT)'),
            obscureText: true,
            validator: (v) => v!.isEmpty ? 'هذا الحقل مطلوب' : null,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveSettings,
            child: const Text('حفظ إعدادات المزامنة'),
          ),
        ],
      ),
    );
  }
}

class _DataManagementTab extends StatelessWidget {
  const _DataManagementTab();

  void _handleMagicLink(BuildContext context) {
    final githubService = context.read<GithubService>();
    if (!githubService.isConfigured) {
      showAppSnackBar(context,
          message: 'الرجاء حفظ إعدادات المزامنة أولاً.',
          type: NotificationType.error);
      return;
    }

    final config = {
      'username': githubService.username,
      'repo': githubService.repo,
      'pat': githubService.token,
    };
    final jsonString = jsonEncode(config);
    final base64String = base64.encode(utf8.encode(jsonString));
    final magicLink =
        'https://rhineix.github.io/WorkShop/#setup=$base64String';

    Share.share(
      'استخدم هذا الرابط لإعداد تطبيق Master Key تلقائياً:\n\n$magicLink',
      subject: 'رابط إعداد Master Key',
    );
  }

  void _handleArchive(BuildContext context) async {
    final dashboardNotifier = context.read<DashboardNotifier>();
    final confirmed = await showConfirmationDialog(
        context: context,
        title: 'تأكيد الأرشفة',
        content:
            'سيتم أرشفة جميع المبيعات الأقدم من 3 أشهر. لا يمكن التراجع عن هذا الإجراء.',
        confirmText: 'أرشفة',
        icon: Symbols.archive,
        isDestructive: false);

    if (confirmed != true || !context.mounted) return;

    try {
      final count = await dashboardNotifier.archiveOldSales();
      if (!context.mounted) return;
      if (count > 0) {
        showAppSnackBar(context,
            message: 'تم أرشفة $count سجل بنجاح',
            type: NotificationType.success);
      } else {
        showAppSnackBar(context,
            message: 'لا توجد مبيعات قديمة للأرشفة',
            type: NotificationType.info);
      }
    } catch (e) {
      if (!context.mounted) return;
      showAppSnackBar(context,
          message: 'فشلت الأرشفة: $e', type: NotificationType.error);
    }
  }

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
          'تم العثور على ${unusedImages.length} صورة غير مستخدمة. هل تريد حذفها نهائياً؟',
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

  void _handleBackup(BuildContext context) async {
    final backupService = BackupService(context.read<GithubService>());
    showAppSnackBar(context,
        message: 'جاري تجهيز النسخة الاحتياطية...', type: NotificationType.info);
    try {
      final String? path = await backupService.createAndSaveBackup();
      if (!context.mounted) return;
      
      if (path != null) {
        showAppSnackBar(context,
            message: 'تم حفظ النسخة في: ${path.split('/').last}',
            type: NotificationType.success);
      } else {
        showAppSnackBar(context,
            message: 'تم إلغاء عملية الحفظ.', type: NotificationType.info);
      }
    } catch (e) {
      if (!context.mounted) return;
      showAppSnackBar(context,
          message: 'فشل إنشاء النسخة الاحتياطية: $e',
          type: NotificationType.error);
    }
  }

  void _handleRestore(BuildContext context) async {
    final confirmed = await showConfirmationDialog(
        context: context,
        title: 'تأكيد الاستعادة',
        content:
            'سيتم استبدال جميع البيانات الحالية بالبيانات الموجودة في ملف النسخة الاحتياطية. هل أنت متأكد؟',
        confirmText: 'استعادة',
        icon: Symbols.warning,
        isDestructive: true);

    if (confirmed != true || !context.mounted) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (!context.mounted) return;

    if (result == null || result.files.single.path == null) {
      showAppSnackBar(context,
          message: 'تم إلغاء اختيار الملف.', type: NotificationType.info);
      return;
    }

    final path = result.files.single.path!;

    try {
      final backupService = BackupService(context.read<GithubService>());
      await backupService.restoreFromBackup(path);
      if (!context.mounted) return;

      context.read<InventoryNotifier>().syncFromNetwork();
      context.read<DashboardNotifier>().syncFromNetwork();
      context.read<SupplierNotifier>().syncFromNetwork();
      context.read<ActivityLogNotifier>().syncFromNetwork();

      showAppSnackBar(context,
          message: 'تم استعادة البيانات ومزامنتها بنجاح',
          type: NotificationType.success);
    } catch (e) {
      if (!context.mounted) return;
      showAppSnackBar(context,
          message: 'فشل استعادة البيانات: $e', type: NotificationType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        ListTile(
          leading: const Icon(Symbols.magic_button),
          title: const Text('إنشاء رابط الإعداد السحري'),
          subtitle: const Text('مشاركة إعدادات المزامنة بسهولة مع جهاز آخر'),
          onTap: () => _handleMagicLink(context),
        ),
        const Divider(height: 24),
        ListTile(
          leading: const Icon(Icons.archive_outlined),
          title: const Text('أرشفة المبيعات القديمة'),
          subtitle: const Text('نقل المبيعات الأقدم من 3 أشهر للأرشيف'),
          onTap: () => _handleArchive(context),
        ),
        ListTile(
          leading: const Icon(Icons.cleaning_services_outlined),
          title: const Text('تنظيف الصور غير المستخدمة'),
          subtitle: const Text('حذف الصور من المستودع التي لا ترتبط بمنتج'),
          onTap: () => _handleImageCleanup(context),
        ),
        const Divider(height: 24),
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: const Text('تنزيل نسخة احتياطية محلية'),
          onTap: () => _handleBackup(context),
        ),
        ListTile(
          leading: const Icon(Icons.upload_outlined),
          title: const Text('استعادة من نسخة احتياطية'),
          onTap: () => _handleRestore(context),
        ),
      ],
    );
  }
}