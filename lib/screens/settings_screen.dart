import 'package:flutter/material.dart';
import '../state/app_controller.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  final AppController controller;
  const SettingsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('الإعدادات', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('حالة الاتصال'),
                subtitle: Text(controller.online ? 'الخادم متاح أو تم الاتصال به بنجاح' : 'لا يوجد اتصال بالخادم — العمل المحلي مستمر'),
                trailing: StatusChip(online: controller.online, queue: controller.queue.length),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('مزامنة الآن'),
                trailing: FilledButton(onPressed: controller.refreshRemote, child: const Text('مزامنة')),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('عنوان API'),
                subtitle: Text(const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000')),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('تصدير نسخة احتياطية'),
                subtitle: const Text('JSON قابل للنقل بين الأجهزة أو النسخ'),
                trailing: FilledButton(onPressed: controller.exportBackup, child: const Text('تصدير')),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('استيراد نسخة احتياطية'),
                trailing: OutlinedButton(onPressed: controller.importBackup, child: const Text('استيراد')),
              ),
            ],
          ),
        ),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              Text('نطاق V1'),
              SizedBox(height: 6),
              Text('المبيعات السريعة، القوائم السعرية، العملاء، تعديل السعر الفعلي، المعاملات المعلقة، استعلام الأسعار، السجل، العمل Offline والـSync Queue، وإدارة البيانات حسب الصلاحية.'),
            ],
          ),
        ),
      ],
    );
  }
}
