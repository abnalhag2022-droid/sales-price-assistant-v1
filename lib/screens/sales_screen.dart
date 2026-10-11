import 'package:flutter/material.dart';
import '../models/models.dart';
import '../state/app_controller.dart';
import '../widgets/common.dart';

class SalesScreen extends StatefulWidget {
  final AppController controller;
  const SalesScreen({super.key, required this.controller});
  @override State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final search = TextEditingController();
  String q = '';
  AppController get ctl => widget.controller;

  @override
  Widget build(BuildContext context) {
    final ticket = ctl.activeTicket;
    final results = ctl.searchItems(q);
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text('فاتورة / استعلام سريع', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
            OutlinedButton.icon(onPressed: ctl.newTicket, icon: const Icon(Icons.add), label: const Text('معاملة جديدة')),
          ]),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: ctl.customerId,
            decoration: const InputDecoration(labelText: 'العميل'),
            items: ctl.customers.map((x) => DropdownMenuItem(value: x.id, child: Text(x.name, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) { if (v != null) ctl.selectCustomer(v); },
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: DropdownButtonFormField<String>(
              value: ctl.priceListId,
              decoration: const InputDecoration(labelText: 'القائمة السعرية'),
              items: ctl.lists.map((x) => DropdownMenuItem(value: x.id, child: Text(x.name, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) { if (v != null) ctl.selectList(v); },
            )),
            if (ticket != null) ...[const SizedBox(width: 8), Text(ctl.money(ticket.total), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17))],
          ]),
        ])),
        TextField(
          controller: search,
          onChanged: (v) => setState(() => q = v),
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'ابحث باسم الصنف أو جزء منه أو رقم الصنف', suffixIcon: Icon(Icons.qr_code_scanner)),
        ),
        const SizedBox(height: 8),
        if (q.isNotEmpty) ...results.map((it) => _result(context, it)),
        if (q.isEmpty && ticket == null) const EmptyState('ابدأ بإنشاء معاملة ثم ابحث عن الصنف. يمكنك كتابة كلمة واحدة مثل: محرك'),
        if (ticket != null) _ticket(context, ticket),
      ],
    );
  }

  Widget _result(BuildContext context, Item it) => Card(
    child: ListTile(
      title: Text(it.name),
      subtitle: Text('${it.code} • ${it.unit}'),
      trailing: Text(ctl.money(ctl.suggestedPrice(it, ctl.priceListId)), style: const TextStyle(fontWeight: FontWeight.w800)),
      onTap: () => _add(context, it),
    ),
  );

  Future<void> _add(BuildContext context, Item item) async {
    final qctl = TextEditingController(text: '1');
    final suggested = ctl.suggestedPrice(item, ctl.priceListId);
    final pctl = TextEditingController(text: suggested.toStringAsFixed(2));
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [Expanded(child: Text('إضافة الصنف', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))), IconButton(onPressed: () => Navigator.pop(ctx, false), icon: const Icon(Icons.close))]),
            Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('${item.code} • ${item.unit}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFF4F7F7), borderRadius: BorderRadius.circular(10)), child: Text('السعر المعتمد من القائمة: ${ctl.money(suggested)}')),
            const SizedBox(height: 10),
            TextField(controller: pctl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'سعر البيع الفعلي لهذه الفاتورة')),
            const SizedBox(height: 10),
            TextField(controller: qctl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'الكمية')),
            const SizedBox(height: 12),
            FilledButton(onPressed: () { final qty = double.tryParse(qctl.text) ?? 0; final price = double.tryParse(pctl.text) ?? -1; Navigator.pop(ctx, qty > 0 && price >= 0); }, child: const Text('إضافة للفاتورة')),
          ]),
        ),
      ),
    );
    if (ok == true) {
      final qty = double.tryParse(qctl.text) ?? 1;
      final price = double.tryParse(pctl.text) ?? suggested;
      await ctl.addLine(item, qty, price);
      search.clear();
      setState(() => q = '');
    }
  }

  Widget _ticket(BuildContext context, Ticket ticket) => SectionCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [Expanded(child: Text('المعاملة ${ticket.id}', style: const TextStyle(fontWeight: FontWeight.w800))), Text(ctl.money(ticket.total), style: const TextStyle(fontWeight: FontWeight.w900))]),
      const Divider(),
      if (ticket.lines.isEmpty) const EmptyState('لا توجد أصناف بعد. ابحث وأضف.'),
      ...List.generate(ticket.lines.length, (i) => _line(context, ticket, i)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: OutlinedButton.icon(onPressed: ctl.pauseActive, icon: const Icon(Icons.pause), label: const Text('تعليق'))),
        const SizedBox(width: 8),
        Expanded(child: FilledButton.icon(onPressed: ticket.lines.isEmpty ? null : () async { await ctl.completeActive(); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنهاء المعاملة وإضافتها للسجل'))); }, icon: const Icon(Icons.check), label: const Text('إتمام البيع'))),
      ]),
    ]),
  );

  Widget _line(BuildContext context, Ticket ticket, int index) {
    final line = ticket.lines[index];
    Item? item;
    for (final x in ctl.items) { if (x.code == line.itemCode) { item = x; break; } }
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(item?.name ?? line.itemCode),
      subtitle: Text('${line.qty} × ${ctl.money(line.price)}'),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(ctl.money(line.qty * line.price), style: const TextStyle(fontWeight: FontWeight.w800)),
        PopupMenuButton<String>(onSelected: (v) async { if (v == 'edit') await _edit(context, ticket, index); if (v == 'delete') await ctl.removeLine(index); }, itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('تعديل')), PopupMenuItem(value: 'delete', child: Text('حذف'))]),
      ]),
    );
  }

  Future<void> _edit(BuildContext context, Ticket ticket, int index) async {
    final line = ticket.lines[index];
    final qctl = TextEditingController(text: line.qty.toString());
    final pctl = TextEditingController(text: line.price.toString());
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [const Expanded(child: Text('تعديل سطر الفاتورة', style: TextStyle(fontWeight: FontWeight.w800))), IconButton(onPressed: () => Navigator.pop(ctx, false), icon: const Icon(Icons.close))]),
            TextField(controller: qctl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'الكمية')),
            const SizedBox(height: 8),
            TextField(controller: pctl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'سعر البيع الفعلي')),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ التعديل')),
          ]),
        ),
      ),
    );
    if (ok == true) {
      final qty = double.tryParse(qctl.text) ?? 0;
      final price = double.tryParse(pctl.text) ?? -1;
      if (qty > 0 && price >= 0) await ctl.editLine(index, qty, price);
    }
  }
}
