import 'package:flutter_test/flutter_test.dart';
import 'package:sales_price_assistant/models/models.dart';
void main(){test('item json roundtrip',(){const x=Item(code:'1',name:'محرك',unit:'حبة',basePrice:100);final y=Item.fromJson(x.toJson());expect(y.code,'1');expect(y.basePrice,100);});test('ticket total',(){final t=Ticket(id:'T',customerId:'CASH',priceListId:'best',createdAt:DateTime(2026,1,1),lines:[TicketLine(itemCode:'1',qty:2,price:50),TicketLine(itemCode:'2',qty:3,price:10)]);expect(t.total,130);});}
