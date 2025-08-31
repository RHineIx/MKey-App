// FILE: lib/src/ui/screens/settings_screen.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
        children: [
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
    _exchangeRateController = TextEditingController(text: settings.exchangeRate.toString());
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
    // This is a synchronous operation after other synchronous operations, context should be fine.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ الإعدادات العامة'), backgroundColor: Colors.green),
    );
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
            final newWeight = fontWeightMap.entries.firstWhere((entry) => entry.value == value).key;
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
    // context.read is fine before await.
    final githubService = context.read<GithubService>();

    await githubService.saveConfig(
      _usernameController.text.trim(),
      _repoController.text.trim(),
      _tokenController.text.trim(),
    );

    if (!mounted) return; // Check State's mounted property

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ إعدادات المزامنة'), backgroundColor: Colors.green),
    );
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
            decoration: const InputDecoration(labelText: 'اسم المستودع (Repository)'),
            validator: (v) => v!.isEmpty ? 'هذا الحقل مطلوب' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _tokenController,
            decoration: const InputDecoration(labelText: 'مفتاح الوصول الشخصي (PAT)'),
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

  void _handleArchive(BuildContext context) async {
    final dashboardNotifier = context.read<DashboardNotifier>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الأرشفة'),
        content: const Text('سيتم أرشفة جميع المبيعات الأقدم من 3 أشهر. لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('أرشفة')),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      final count = await dashboardNotifier.archiveOldSales();
      if (!context.mounted) return;
      if (count > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم أرشفة $count سجل بنجاح'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد مبيعات قديمة للأرشفة')),
        );
      }
    } catch(e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشلت الأرشفة: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _handleImageCleanup(BuildContext context) async {
    final inventoryNotifier = context.read<InventoryNotifier>();

    final List<GithubFile> unusedImages = await inventoryNotifier.findUnusedImages();

    if (!context.mounted) return;

    if (unusedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد صور غير مستخدمة ليتم حذفها.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('تم العثور على ${unusedImages.length} صورة غير مستخدمة. هل تريد حذفها نهائياً؟'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text('نعم، حذف ${unusedImages.length} صورة')),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      final deletedCount = await inventoryNotifier.deleteUnusedImages(unusedImages);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('اكتمل التنظيف. تم حذف $deletedCount صورة بنجاح.'), backgroundColor: Colors.green),
      );
    } catch(e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل حذف الصور: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _handleBackup(BuildContext context) async {
    final backupService = BackupService(context.read<GithubService>());

    // Show SnackBar before await - context is valid here.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جاري تجهيز النسخة الاحتياطية...')),
    );

    try {
      await backupService.createAndSaveBackup();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ النسخة الاحتياطية بنجاح.'), backgroundColor: Colors.green),
      );
    } catch(e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل إنشاء النسخة الاحتياطية: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _handleRestore(BuildContext context) async {
    final backupService = BackupService(context.read<GithubService>());
    final inventoryNotifier = context.read<InventoryNotifier>();
    final dashboardNotifier = context.read<DashboardNotifier>();
    final supplierNotifier = context.read<SupplierNotifier>();
    final activityLogNotifier = context.read<ActivityLogNotifier>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد الاستعادة'),
        content: const Text('سيتم استبدال جميع البيانات الحالية بالبيانات الموجودة في ملف النسخة الاحتياطية. هل أنت متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('استعادة')),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;


    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (!context.mounted) return;

    if (result == null || result.files.single.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إلغاء اختيار الملف.')));
      return;
    }

    final path = result.files.single.path!;

    try {
      await backupService.restoreFromBackup(path);

      if (!context.mounted) return;

      inventoryNotifier.syncFromNetwork();
      dashboardNotifier.syncFromNetwork();
      supplierNotifier.syncFromNetwork();
      activityLogNotifier.syncFromNetwork();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم استعادة البيانات ومزامنتها بنجاح'), backgroundColor: Colors.green),
      );
    } catch(e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل استعادة البيانات: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
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
