import 'package:flutter/material.dart';
import '../state/app_controller.dart';
import '../widgets/common.dart';

class HistoryScreen extends StatelessWidget {
  final AppController controller;
  const HistoryScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        SectionCard(
          child: Row(
            children: [
              Expanded(child: Text('سجل الأسعار والمعاملات', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
              Text('${controller.history.length}', style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        if (controller.history.isEmpty) const EmptyState('لا يوجد سجل محلي بعد.'),
        ...controller.history.map((h) => Card(
          child: ListTile(
            title: Text(h.type),
            subtitle: Text('${h.itemCode.isEmpty ? '' : '${h.itemCode} • '}${h.ticketId} • ${controller.date(h.date)}'),
            trailing: Text(
              h.price != null ? controller.money(h.price!) : h.total != null ? controller.money(h.total!) : '',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        )),
      ],
    );
  }
}
