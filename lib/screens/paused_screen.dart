import 'package:flutter/material.dart';
import '../state/app_controller.dart';
import '../widgets/common.dart';

class PausedScreen extends StatelessWidget {
  final AppController controller;
  const PausedScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final paused = controller.tickets.where((x) => x.id != controller.activeTicketId).toList();
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('المعاملات المعلقة', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (paused.isEmpty) const EmptyState('لا توجد معاملات معلقة.'),
              ...paused.map((t) => ListTile(
                title: Text(t.id),
                subtitle: Text('${t.lines.length} أصناف • ${_customerName(t.customerId)}'),
                trailing: FilledButton(onPressed: () => controller.resume(t.id), child: const Text('استئناف')),
              )),
            ],
          ),
        ),
      ],
    );
  }

  String _customerName(String id) {
    for (final x in controller.customers) { if (x.id == id) return x.name; }
    return id;
  }
}
