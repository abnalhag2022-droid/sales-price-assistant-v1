import 'package:flutter/material.dart';
import '../models/models.dart';
import '../state/app_controller.dart';
import '../widgets/common.dart';

class AdminScreen extends StatefulWidget {
  final AppController controller;
  const AdminScreen({super.key, required this.controller});
  @override State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  AppController get ctl => widget.controller;

  @override
  Widget build(BuildContext context) {
    final p = ctl.adminPage;
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        SectionCard(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          _tab('items', 'الأصناف'), _tab('customers', 'العملاء'), _tab('lists', 'القوائم السعرية'), _tab('users', 'المستخدمون'),
        ]))),
        if (p == 'items') _items(context)
        else if (p == 'customers') _customers(context)
        else if (p == 'lists') _lists(context)
        else _users(context),
      ],
    );
  }

  Widget _tab(String id, String label) => Padding(
    padding: const EdgeInsets.only(left: 6),
    child: ChoiceChip(label: Text(label), selected: ctl.adminPage == id, onSelected: (_) {
      ctl.adminPage = id;
      ctl.persist();
      setState(() {});
    }),
  );

  Widget _items(BuildContext context) => _section(
    context, 'الأصناف',
    ctl.items.map((x) => '${x.code} — ${x.name} — ${ctl.money(x.basePrice)}').toList(),
    () => _itemForm(context),
  );

  Widget _customers(BuildContext context) => _section(
    context, 'العملاء',
    ctl.customers.map((x) => '${x.name} — ${x.priceListId}').toList(),
    () => _customerForm(context),
  );

  Widget _lists(BuildContext context) => SectionCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [Expanded(child: Text('القوائم السعرية', style: const TextStyle(fontWeight: FontWeight.w800))), FilledButton.icon(onPressed: () => _listForm(context), icon: const Icon(Icons.add), label: const Text('إضافة'))]),
      const SizedBox(height: 8),
      ...ctl.lists.map((x) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(x.name),
        subtitle: Text('خصم ${x.discountPercent}% • أسعار ثابتة: ${x.itemPrices.length}'),
        trailing: OutlinedButton(onPressed: () => _listPricesForm(context, x), child: const Text('أسعار الأصناف')),
      )),
    ]),
  );

  Widget _users(BuildContext context) => _section(context, 'المستخدمون', ctl.users.map((x) => '${x.displayName} — ${x.role}').toList(), () => _userForm(context));

  Widget _section(BuildContext context, String title, List<String> rows, VoidCallback add) => SectionCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))), FilledButton.icon(onPressed: add, icon: const Icon(Icons.add), label: const Text('إضافة'))]),
      const SizedBox(height: 8),
      ...rows.map((x) => ListTile(contentPadding: EdgeInsets.zero, title: Text(x))),
    ]),
  );

  Future<void> _itemForm(BuildContext context) async {
    final code = TextEditingController(), name = TextEditingController(), unit = TextEditingController(text: 'حبة'), price = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (d) => AlertDialog(
      title: const Text('إضافة صنف'),
      content: SingleChildScrollView(child: Column(children: [
        TextField(controller: code, decoration: const InputDecoration(labelText: 'رقم الصنف')),
        TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم الصنف')),
        TextField(controller: unit, decoration: const InputDecoration(labelText: 'الوحدة')),
        TextField(controller: price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'السعر الأساسي')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('إغلاق')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('حفظ'))],
    ));
    if (ok == true && code.text.isNotEmpty && name.text.isNotEmpty) await ctl.upsertItem(code: code.text.trim(), name: name.text.trim(), unit: unit.text.trim(), basePrice: double.tryParse(price.text) ?? 0);
  }

  Future<void> _customerForm(BuildContext context) async {
    final name = TextEditingController();
    String list = ctl.lists.isEmpty ? '' : ctl.lists.first.id;
    final ok = await showDialog<bool>(context: context, builder: (d) => StatefulBuilder(builder: (d, set) => AlertDialog(
      title: const Text('إضافة عميل'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم العميل')),
        if (ctl.lists.isNotEmpty) DropdownButtonFormField<String>(initialValue: list, items: ctl.lists.map((x) => DropdownMenuItem(value: x.id, child: Text(x.name))).toList(), onChanged: (v) => set(() => list = v ?? list), decoration: const InputDecoration(labelText: 'القائمة الافتراضية')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('إغلاق')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('حفظ'))],
    )));
    if (ok == true && name.text.isNotEmpty) await ctl.upsertCustomer(name: name.text.trim(), listId: list);
  }

  Future<void> _listForm(BuildContext context) async {
    final name = TextEditingController(), discount = TextEditingController(text: '0');
    final ok = await showDialog<bool>(context: context, builder: (d) => AlertDialog(
      title: const Text('إضافة قائمة سعرية'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'اسم القائمة')),
        TextField(controller: discount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'الخصم %')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('إغلاق')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('حفظ'))],
    ));
    if (ok == true && name.text.isNotEmpty) await ctl.upsertList(name: name.text.trim(), discount: double.tryParse(discount.text) ?? 0);
  }

  Future<void> _listPricesForm(BuildContext context, PriceList list) async {
    String q='';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => StatefulBuilder(builder: (sheet, set) {
        final arr=ctl.searchItems(q);
        return Directionality(textDirection: TextDirection.rtl, child: SizedBox(height: MediaQuery.of(sheet).size.height*0.85, child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
          Row(children: [Expanded(child: Text('أسعار الأصناف — ${list.name}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17))), IconButton(onPressed: () => Navigator.pop(sheet), icon: const Icon(Icons.close))]),
          TextField(onChanged: (v) => set(() => q=v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'بحث عن صنف')),
          const SizedBox(height: 8),
          Expanded(child: ListView(children: arr.map((it) {
            final currentList=ctl.lists.firstWhere((x)=>x.id==list.id); final priceCtl=TextEditingController(text: currentList.itemPrices[it.code]?.toString() ?? '');
            return ListTile(title: Text(it.name), subtitle: Text('${it.code} • ${it.unit}'), trailing: SizedBox(width: 130, child: TextField(controller: priceCtl, keyboardType: const TextInputType.numberWithOptions(decimal:true), decoration: InputDecoration(labelText: 'السعر', suffixIcon: IconButton(icon: const Icon(Icons.save), onPressed: () async { final v=double.tryParse(priceCtl.text); await ctl.setListItemPrice(list.id,it.code,v); setState((){}); })))));
          }).toList())),
        ]))));
      }),
    );
  }

  Future<void> _userForm(BuildContext context) async {
    final username = TextEditingController(), name = TextEditingController();
    String role = 'sales';
    final ok = await showDialog<bool>(context: context, builder: (d) => StatefulBuilder(builder: (d, set) => AlertDialog(
      title: const Text('إضافة مستخدم'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: username, decoration: const InputDecoration(labelText: 'اسم المستخدم')),
        TextField(controller: name, decoration: const InputDecoration(labelText: 'الاسم الظاهر')),
        DropdownButtonFormField<String>(initialValue: role, items: const [DropdownMenuItem(value: 'sales', child: Text('مبيعات')), DropdownMenuItem(value: 'store', child: Text('مخزن')), DropdownMenuItem(value: 'admin', child: Text('مدير'))], onChanged: (v) => set(() => role = v ?? role), decoration: const InputDecoration(labelText: 'الصلاحية')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('إغلاق')), FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('حفظ'))],
    )));
    if (ok == true && username.text.isNotEmpty) {
      ctl.users.add(UserAccount(username: username.text.trim(), displayName: name.text.trim().isEmpty ? username.text.trim() : name.text.trim(), role: role));
      await ctl.persist();
        setState(() {});
    }
  }
}
