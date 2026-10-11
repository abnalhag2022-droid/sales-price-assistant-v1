import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/local_store.dart';
import '../services/sync_service.dart';

class AppController extends ChangeNotifier {
  final LocalStore store=LocalStore();
  late final ApiService api;
  late final SyncService sync;
  bool booted=false, online=false, busy=false;
  UserAccount? user;
  List<Item> items=[]; List<Customer> customers=[]; List<PriceList> lists=[]; List<UserAccount> users=[];
  List<Ticket> tickets=[]; String? activeTicketId;
  List<HistoryEntry> history=[]; List<QueueOperation> queue=[];
  String page='sales'; String adminPage='items';
  String customerId='CASH'; String priceListId='best';
  String? error;

  bool get isLoggedIn=>user!=null;
  Ticket? get activeTicket { for (final t in tickets) { if (t.id == activeTicketId) return t; } return null; }
  Customer? get customer=>customers.where((x)=>x.id==customerId).cast<Customer?>().firstWhere((x)=>x!=null,orElse:()=>null);
  PriceList? get priceList=>lists.where((x)=>x.id==priceListId).cast<PriceList?>().firstWhere((x)=>x!=null,orElse:()=>null);

  Future<void> bootstrap() async {
    await store.init();
    final session=await store.readAuthSession();
    api=ApiService(baseUrl:store.apiBaseUrl,session:session);
    api.onSessionChanged=store.writeAuthSession;
    api.onSessionRevoked=() async { await store.clearAuthSession(); user=null; };
    sync=SyncService(api);
    final saved=store.read(); if(saved!=null) _restore(saved);
    if(session!=null){user=session.user;}
    if(items.isEmpty) _seed();
    booted=true; notifyListeners();
  }

  void _seed(){
    items=_seedItems.map((e)=>Item(code:e[0] as String,name:e[1] as String,unit:e[2] as String,basePrice:(e[3] as num).toDouble())).toList();
    customers=[const Customer(id:'CASH',name:'ط¹ظ…ظ„ط§ط، ط§ظ„ظ…ط¨ظٹط¹ط§طھ ط§ظ„ظ†ظ‚ط¯ظٹط©',priceListId:'best'),const Customer(id:'A',name:'ط§ظ„ط¹ظ…ظٹظ„ ط£ظ„ظپ',priceListId:'gold'),const Customer(id:'B',name:'ط§ظ„ط¹ظ…ظٹظ„ ط¨ط§ط،',priceListId:'wholesale'),const Customer(id:'C',name:'ط§ظ„ط¹ظ…ظٹظ„ ط¬ظٹظ…',priceListId:'custom'),const Customer(id:'D',name:'ط¹ظ…ظٹظ„ ط®ط§طµ â€” ظ‚ط§ط¦ظ…ط© ظٹط¯ظˆظٹط©',priceListId:'best')];
    lists=[const PriceList(id:'base',name:'ط§ظ„ط³ط¹ط± ط§ظ„ط£ط³ط§ط³ظٹ',discountPercent:0),const PriceList(id:'wholesale',name:'ظ‚ط§ط¦ظ…ط© ط§ظ„ط¬ظ…ظ„ط©',discountPercent:8),const PriceList(id:'gold',name:'ظ‚ط§ط¦ظ…ط© ط®ط§طµط© - ط®طµظ… 8%',discountPercent:8),const PriceList(id:'custom',name:'ظ‚ط§ط¦ظ…ط© ط®ط§طµط© - ط®طµظ… 12%',discountPercent:12),const PriceList(id:'best',name:'ط£ظپط¶ظ„ ط³ط¹ط± / ط£ط¹ظ„ظ‰ ط®طµظ…',discountPercent:15)];
    users=[const UserAccount(username:'admin',displayName:'ظ…ط¯ظٹط± ط§ظ„ظ†ط¸ط§ظ…',role:'admin'),const UserAccount(username:'sales',displayName:'ظ…ظˆط¸ظپ ظ…ط¨ظٹط¹ط§طھ',role:'sales'),const UserAccount(username:'store',displayName:'ط§ظ„ظ…ط®ط²ظ†',role:'store')];
  }

  Map<String,dynamic> exportState() => {'user':user?.toJson(),'items':items.map((e)=>e.toJson()).toList(),'customers':customers.map((e)=>e.toJson()).toList(),'lists':lists.map((e)=>e.toJson()).toList(),'users':users.map((e)=>e.toJson()).toList(),'tickets':tickets.map((e)=>e.toJson()).toList(),'active':activeTicketId,'history':history.map((e)=>e.toJson()).toList(),'queue':queue.map((e)=>e.toJson()).toList(),'customer':customerId,'list':priceListId,'page':page,'adminPage':adminPage};

  Future<void> exportBackup() async {
    final dir=await getTemporaryDirectory();
    final file=File('${dir.path}/sales_price_assistant_backup.json');
    await file.writeAsString(jsonEncode(exportState()));
    await Share.shareXFiles([XFile(file.path)], text:'ظ†ط³ط®ط© ط§ط­طھظٹط§ط·ظٹط© ظ…ظ† ظ…ط³ط§ط¹ط¯ ط§ظ„ظ…ط¨ظٹط¹ط§طھ');
  }

  Future<void> importBackup() async {
    final result=await FilePicker.platform.pickFiles(type:FileType.custom,allowedExtensions:['json'],withData:true);
    if(result==null||result.files.single.bytes==null){return;}
    final data=jsonDecode(utf8.decode(result.files.single.bytes!));
    _restore(Map<String,dynamic>.from(data));
    await persist();
    notifyListeners();
  }

  Future<void> persist() async { await store.write(exportState()); }
  void _restore(Map<String,dynamic> s){
    final u=s['user']; if(u is Map) user=UserAccount.fromJson(Map<String,dynamic>.from(u));
    items=((s['items']??[]) as List).map((e)=>Item.fromJson(Map<String,dynamic>.from(e))).toList();
    customers=((s['customers']??[]) as List).map((e)=>Customer.fromJson(Map<String,dynamic>.from(e))).toList();
    lists=((s['lists']??[]) as List).map((e)=>PriceList.fromJson(Map<String,dynamic>.from(e))).toList();
    users=((s['users']??[]) as List).map((e)=>UserAccount.fromJson(Map<String,dynamic>.from(e))).toList();
    tickets=((s['tickets']??[]) as List).map((e)=>Ticket.fromJson(Map<String,dynamic>.from(e))).toList(); activeTicketId=s['active'] as String?;
    history=((s['history']??[]) as List).map((e)=>HistoryEntry.fromJson(Map<String,dynamic>.from(e))).toList(); queue=((s['queue']??[]) as List).map((e)=>QueueOperation.fromJson(Map<String,dynamic>.from(e))).toList();
    customerId='${s['customer']??'CASH'}'; priceListId='${s['list']??'best'}'; page='${s['page']??'sales'}'; adminPage='${s['adminPage']??'items'}';
  }

  Future<bool> login(String username,String password,{bool demo=false}) async {
    busy=true; error=null; notifyListeners();
    try { if(demo){ user=users.firstWhere((x)=>x.username==username,orElse:()=>UserAccount(username:username,displayName:username,role:username=='admin'?'admin':'sales')); }
      else { final session=await api.login(username,password); user=session.user; }
      await persist(); return true;
    } catch(e){ error=e.toString(); return false; } finally { busy=false; notifyListeners(); }
  }
  Future<void> logout() async { await api.logout(); user=null; activeTicketId=null; page='sales'; await persist(); notifyListeners(); }
  Future<void> refreshRemote() async {
    if(!isLoggedIn){return;} busy=true; notifyListeners();
    try { online=await api.health(); if(online){ await sync.flush(queue); items=await api.items(); customers=await api.customers(); lists=await api.priceLists(); if(can('users:read')) users=await api.users(); await persist(); } }
    catch(e){ online=false; error=e.toString(); } finally { busy=false; notifyListeners(); }
  }
  bool can(String permission)=>user?.can(permission)??false;
  void selectCustomer(String id){customerId=id; final c=customer; if(c!=null){priceListId=c.priceListId;} persist(); notifyListeners();}
  void selectList(String id){priceListId=id; persist(); notifyListeners();}
  double suggestedPrice(Item item,String listId){ final l=lists.firstWhere((x)=>x.id==listId,orElse:()=>const PriceList(id:'base',name:'ط§ظ„ط³ط¹ط± ط§ظ„ط£ط³ط§ط³ظٹ',discountPercent:0)); return l.priceFor(item.code) ?? item.basePrice*(1-l.discountPercent/100); }
  void newTicket(){ final id='T-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999)}'; final t=Ticket(id:id,customerId:customerId,priceListId:priceListId,createdAt:DateTime.now(),localOnly:!online); tickets.add(t); activeTicketId=id; queue.add(QueueOperation(id:operationId(),type:'create_session',payload:{'ticket_id':id,'customer_id':customerId,'price_list_id':priceListId})); persist(); notifyListeners(); }
  void pauseActive(){activeTicketId=null; persist(); notifyListeners();}
  void resume(String id){activeTicketId=id; page='sales'; persist(); notifyListeners();}
  String operationId()=> '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(999999)}';
  Future<void> addLine(Item item,double qty,double price) async { if(activeTicket==null){newTicket();} final t=activeTicket!; final reference=suggestedPrice(item,t.priceListId); final line=TicketLine(itemCode:item.code,qty:qty,price:price,priceListId:t.priceListId,referencePrice:reference); t.lines.add(line); t.updatedAt=DateTime.now(); final op=operationId(); queue.add(QueueOperation(id:op,type:'add_line',payload:{'ticket_id':t.id,'item_code':item.code,'qty':qty,'price':price,'price_list_id':t.priceListId,'reference_price':reference})); if(online){await refreshRemote();} await persist(); notifyListeners(); }
  Future<void> editLine(int index,double qty,double price) async { final t=activeTicket; if(t==null||index<0||index>=t.lines.length){return;} final l=t.lines[index]; l.qty=qty;l.price=price;t.updatedAt=DateTime.now();final op=operationId(); queue.add(QueueOperation(id:op,type:'edit_line',payload:{'ticket_id':t.id,'item_code':l.itemCode,'qty':qty,'price':price})); history.insert(0,HistoryEntry(type:'تعديل سعر/كمية',ticketId:t.id,itemCode:l.itemCode,qty:qty,price:price,priceListId:t.priceListId,date:DateTime.now())); if(online){await refreshRemote();} await persist(); notifyListeners(); }
  Future<void> removeLine(int index) async { final t=activeTicket;if(t==null||index<0||index>=t.lines.length){return;} final code=t.lines[index].itemCode;t.lines.removeAt(index);t.updatedAt=DateTime.now();final op=operationId();queue.add(QueueOperation(id:op,type:'delete_line',payload:{'ticket_id':t.id,'item_code':code}));if(online){await refreshRemote();}await persist();notifyListeners(); }
  Future<void> completeActive() async { final t=activeTicket;if(t==null||t.lines.isEmpty){return;} final op=operationId();queue.add(QueueOperation(id:op,type:'complete',payload:{'ticket_id':t.id})); if(online){await refreshRemote();} history.insert(0,HistoryEntry(type:'إتمام بيع',ticketId:t.id,total:t.total,priceListId:t.priceListId,date:DateTime.now())); tickets.removeWhere((x)=>x.id==t.id);activeTicketId=null;await persist();notifyListeners(); }
  List<Item> searchItems(String q){ final s=q.trim().toLowerCase();if(s.isEmpty){return items.take(40).toList();}return items.where((x)=>x.code.toLowerCase().contains(s)||x.name.toLowerCase().contains(s)||x.unit.toLowerCase().contains(s)||x.aliases.any((a)=>a.toLowerCase().contains(s))).toList(); }
  String money(double v)=>NumberFormat('#,##0.##','ar_YE').format(v)+' ط±.ظٹ';
  String date(DateTime d)=>DateFormat('yyyy/MM/dd HH:mm','ar_YE').format(d);

  Future<void> upsertItem({String? id,required String code,required String name,required String unit,required double basePrice}) async {final local=Item(code:code,name:name,unit:unit,basePrice:basePrice);final i=items.indexWhere((x)=>x.code==(id??code));if(i>=0){items[i]=local;}else{items.add(local);}final op=operationId();queue.add(QueueOperation(id:op,type:'admin_upsert',payload:{'resource':'items','id':id??code,'body':local.toJson()}));if(online){await refreshRemote();}await persist();notifyListeners();}
  Future<void> upsertCustomer({String? id,required String name,required String listId}) async {final c=Customer(id:id??'C-${DateTime.now().millisecondsSinceEpoch}',name:name,priceListId:listId);final i=customers.indexWhere((x)=>x.id==c.id);if(i>=0){customers[i]=c;}else{customers.add(c);}final op=operationId();queue.add(QueueOperation(id:op,type:'admin_upsert',payload:{'resource':'customers','id':id,'body':c.toJson()}));if(online){await refreshRemote();}await persist();notifyListeners();}
  Future<void> setListItemPrice(String listId, String itemCode, double? price) async {
    final idx=lists.indexWhere((x)=>x.id==listId);
    if(idx<0){return;}
    final current=lists[idx];
    final prices=Map<String,double>.from(current.itemPrices);
    if(price==null){prices.remove(itemCode);}else{prices[itemCode]=price;}
    lists[idx]=PriceList(id:current.id,name:current.name,discountPercent:current.discountPercent,itemPrices:prices);
    final op=operationId();queue.add(QueueOperation(id:op,type:'admin_upsert',payload:{'resource':'price-lists','id':listId,'body':lists[idx].toJson()}));
    if(online){await refreshRemote();}
    await persist();notifyListeners();
  }

  Future<void> upsertList({String? id,required String name,required double discount,Map<String,double>? itemPrices}) async {final l=PriceList(id:id??'L-${DateTime.now().millisecondsSinceEpoch}',name:name,discountPercent:discount,itemPrices:itemPrices??const {});final i=lists.indexWhere((x)=>x.id==l.id);if(i>=0){lists[i]=l;}else{lists.add(l);}final op=operationId();queue.add(QueueOperation(id:op,type:'admin_upsert',payload:{'resource':'price-lists','id':id,'body':l.toJson()}));if(online){await refreshRemote();}await persist();notifyListeners();}

  static const _seedItems=<List<dynamic>>[
    ['200-006-221','طھظˆط§طµظٹظ„ ظ†ط­ط§ط³ ظ„ظٹ ط±ط´ ط°ظƒط± ظˆط§ظ†ط«ظ‰ ط±ط¨ط¹ ظ‡ظ†ط´','ط­ط¨ط©',400],['200-003-097','ط®ظˆطµ ظ„ظٹط§طھ ط±ط´','ط­ط¨ط©',50],['200-004-047','ط´ظ„ظٹط´ط§ظ† ظ…ظ„ظˆظ† ظƒط±ط³طھط§ظ„','ط­ط¨ط©',200],['200-004-074','ظ„ظ…ط¨ ط¬ظˆط¯ط² ظ…ط·ظˆط± 5 ظˆط§طھ 12 ظپظˆظ„طھ','ط­ط¨ط©',500],['200-003-244','ط؛ط±ط§ط، ظ†طµظپ ظƒظٹظ„ظˆ ط¨ط§ط±ط¯ 5117 A S U Global','ط­ط¨ط©',3000],['200-005-306','ظ…ط¨ظٹط¯ ط§ط¬ط±ظ†ظٹطھ ط§ظ„ط¹ظ…ظ„ط§ظ‚ 100 ط¬ط±ط§ظ… (ظ…ظٹط«ظˆظ…ظٹظ„)','ط¸ط±ظپ',2250],['200-005-307','ظ…ط¨ظٹط¯ ط¨ط±ط¬ ط³ظٹظƒظ„ط§ظ… 50 ط¬ط±ط§ظ… (ط«ظٹظˆط³ظٹظƒظ„ط§ظ…)','ط¸ط±ظپ',1000],['200-002-219','ظ‚ط§ط¹ط¯ط© ظ„ظٹ ط´ظپط· ط¨ظ…ط¨ ط±ط´ 22','ط­ط¨ط©',1500],['200-006-054','ظ…ط­ط¨ط³ ط¨ظ„ط§ط³طھظٹظƒ طھط±ظٹطھ ظƒط±ظˆظ… ط§ط¨ظˆ 3/4 ظ‡ظ†ط´','ط­ط¨ط©',500],['200-003-263','ظ…ط­ظˆظ„ ط­ط¯ظٹط¯ 3/4 * 1/2 ظ‡ظ†ط´','ط­ط¨ط©',250],['200-006-158','ظ†ظٹط¨ظ„ ط´ط±ظٹط· 3/4ظ‡ظ†ط´ ط­ط¯ظٹط¯','ط­ط¨ط©',250],['200-006-172','ط¨ط§ظ†ط§طھ 13 ظƒط±ظˆظ…','ط­ط¨ط©',500],['200-004-374','ط¬ظˆظ†طھظٹ ط­ط±ط§ط±ظٹ 25 ظ…ظ„ظٹ','ط­ط¨ط©',4000],['200-006-128','ط³ظ„ظƒ طھط±ط¨ظٹط· ط§ط¨ظˆ 1 ظƒط¬ظ…','ظ„ظپط©',1000],['200-005-304','ظ…ط¨ظٹط¯ ط§ظˆظ„ ظ…ط«ط±ظٹظ† 250 ظ…ظ„ظٹ (ط¯ظ„طھط§ظ…ط«ط±ظٹظ†)','ط¹ظ„ط¨ط©',2000],['200-003-188','ط·ط±ط¨ط§ظ„ ط§ط¨ظٹط¶ ظ…ط¯ط±ط¹ 4*6','ط­ط¨ط©',3000],['200-006-301','ظ…ط±ط§ط¨ظٹط· 500أ—7 ظ…ظ„ظٹ ط¹ط§ط¯ظٹ','ط´ط¯ط©',3000],['200-005-368','ظ…ط¨ظٹط¯ ظپظٹظ†ظˆط²ظٹط¯ 250 ظ…ظ„ظٹ (ط§ط¨ط§ظ…ظƒطھظٹظ† + ظ…ظٹط«ظˆظƒط³ظٹ ظپظٹظ†ظˆط²ظٹط¯)','ط¹ظ„ط¨ط©',3200],['200-002-065','ط±ظƒط¨ ظƒط¨ط³ 16 * 16 ظ…ظ… ط³ظ†ظƒط±ظˆظ† طھط±ظƒظٹ','ط­ط¨ط©',30],['200-002-357','ظ…ط«ظ„ظˆط« ظƒط¨ط³ 16 ظ…ظ„ ط³ط¹ظˆط¯ظٹ ظ…ظٹط³','ط­ط¨ط©',50],['200-002-168','ظ†ظٹط¨ظ„ ط¬ظ‡طھ 0.75 ط³ظ†ظƒط±ظˆظ† طھط±ظƒظٹ','ط­ط¨ط©',150],['200-003-325','ظ…ط«ظ„ظˆط« ط¨ظ„ط§ط³طھظٹظƒ 4 ظ‡ظ†ط´ ط¬ط§ظپظٹ ط¨ظ„ط§ط³ظƒظˆ','ط­ط¨ط©',1000],['200-003-187','ط·ط±ط¨ط§ظ„ ط§ط¨ظٹط¶ ظ…ط¯ط±ط¹ 3*4','ط­ط¨ط©',1700],['200-004-097','ط¯ط³ط§ظ…ظٹط³ ظƒظ‡ط±ط¨ط§ط، ط§ط¨ظˆ ظƒط±طھ ط§ظ„ط§طµظ„ظٹ طµط؛ظٹط±','ط­ط¨ط©',400],['200-002-262','ظ…ط³ط¯ط³ ط¨ظ…ط¨ ط±ط´ ظ‚طµظٹط± ط§ظ„ط§طµظ„ظٹ 45','ط­ط¨ط©',1000],['200-006-055','ظ„طµظƒط© ط³ط¨ط§ظƒظ‡ طµط؛ظٹط± ط§ط®ط¶ط±','ط­ط¨ط©',150],['200-003-326','ظƒظˆط¹ ط²ط§ظˆظٹط© 4 ظ‡ظ†ط´ ط¬ط§ظپظٹ','ط­ط¨ط©',950],['200-003-335','ط³ط§ظƒطھ 110 ظ…ظ„ظٹ ط®ظپظٹظپ','ط­ط¨ط©',250],['200-006-258','ظپط±ط´ ط±ظ†ط¬ 3 ظ‡ظ†ط´ ط§ظ„ط§طµظ„ظٹ','ط­ط¨ط©',500],['200-006-336','ط³ظƒط§ظƒظٹظ† ظ…ط´ط§ط±ط· ط¬ط§ظپظٹ','ط·ظ‚ظ…',500],['200-005-308','ظ…ط¨ظٹط¯ ط²ط±ط§ط¹ظٹ طھط¬ط±ظٹط¨ظٹ','ط¹ظ„ط¨ط©',1800],['200-006-400','ظ…ط­ط±ظƒ ط±ط´ طµط؛ظٹط±','ط­ط¨ط©',8500],['200-006-401','ظ…ط­ط±ظƒ ط±ط´ ظ…طھظˆط³ط·','ط­ط¨ط©',12500],['200-006-402','ط³ظ„ظƒ ظƒظ‡ط±ط¨ط§ط، ط²ط±ط§ط¹ظٹ','ظ„ظپط©',2200],['200-006-403','ظ…ط¶ط®ط© ظ…ط§ط، طµط؛ظٹط±ط©','ط­ط¨ط©',15000],['200-006-404','ظ…ظپطھط§ط­ طھط´ط؛ظٹظ„ ظ…ط¶ط®ط©','ط­ط¨ط©',900],
  ];
}
