import 'package:flutter/material.dart';
import '../state/app_controller.dart';
import '../widgets/common.dart';
import 'admin_screen.dart';
import 'history_screen.dart';
import 'inquiry_screen.dart';
import 'paused_screen.dart';
import 'sales_screen.dart';
import 'settings_screen.dart';

class ShellScreen extends StatelessWidget {
  final AppController controller;
  const ShellScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مساعد المبيعات', style: TextStyle(fontWeight: FontWeight.w800)),
          actions: [
            StatusChip(online: controller.online, queue: controller.queue.length),
            const SizedBox(width: 8),
            IconButton(onPressed: controller.refreshRemote, icon: const Icon(Icons.sync)),
          ],
        ),
        drawer: Drawer(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: [
                ListTile(
                  title: Text(controller.user?.displayName ?? ''),
                  subtitle: Text(controller.user?.role ?? ''),
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                ),
                const Divider(),
                ..._nav(context),
                if (controller.can('admin:*'))
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings),
                    title: const Text('الإدارة'),
                    selected: controller.page == 'admin',
                    onTap: () {
                      controller.page = 'admin';
                      controller.persist();
                                      Navigator.pop(context);
                    },
                  ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('تسجيل الخروج'),
                  onTap: () {
                    controller.logout();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
        body: _body(),
      ),
    );
  }

  List<Widget> _nav(BuildContext context) => [
    const MapEntry('sales', 'المبيعات'),
    const MapEntry('paused', 'المعاملات المعلقة'),
    const MapEntry('inquiry', 'استعلام الأسعار'),
    const MapEntry('history', 'السجل'),
    const MapEntry('settings', 'الإعدادات'),
  ].map((e) => ListTile(
    title: Text(e.value),
    leading: Icon(_icon(e.key)),
    selected: controller.page == e.key,
    onTap: () {
      controller.page = e.key;
      controller.persist();
      Navigator.pop(context);
    },
  )).toList();

  IconData _icon(String p) => {
    'sales': Icons.point_of_sale,
    'paused': Icons.pause_circle_outline,
    'inquiry': Icons.search,
    'history': Icons.history,
    'settings': Icons.settings,
  }[p] ?? Icons.circle;

  Widget _body() {
    switch (controller.page) {
      case 'paused': return PausedScreen(controller: controller);
      case 'inquiry': return InquiryScreen(controller: controller);
      case 'history': return HistoryScreen(controller: controller);
      case 'settings': return SettingsScreen(controller: controller);
      case 'admin': return AdminScreen(controller: controller);
      default: return SalesScreen(controller: controller);
    }
  }
}
