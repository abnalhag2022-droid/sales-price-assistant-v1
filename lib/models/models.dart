enum QueueStatus { pending, inFlight, acknowledged, failed, conflict }

QueueStatus queueStatusFromString(String? value) {
  for (final status in QueueStatus.values) {
    if (status.name == value) return status;
  }
  return QueueStatus.pending;
}

class Item {
  final String code;
  final String name;
  final String unit;
  final double basePrice;
  final List<String> aliases;

  const Item({
    required this.code,
    required this.name,
    required this.unit,
    required this.basePrice,
    this.aliases = const [],
  });

  factory Item.fromJson(Map<String, dynamic> j) => Item(
        code: '${j['code'] ?? j['item_code'] ?? ''}',
        name: '${j['name'] ?? j['item_name'] ?? ''}',
        unit: '${j['unit'] ?? ''}',
        basePrice: _num(j['base_price'] ?? j['price'] ?? 0),
        aliases: _stringList(j['aliases'] ?? j['search_aliases']),
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'unit': unit,
        'base_price': basePrice,
        'aliases': aliases,
      };
}

class Customer {
  final String id;
  final String name;
  final String priceListId;
  final String? groupId;

  const Customer({
    required this.id,
    required this.name,
    required this.priceListId,
    this.groupId,
  });

  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
        id: '${j['id'] ?? j['customer_id'] ?? ''}',
        name: '${j['name'] ?? j['customer_name'] ?? ''}',
        priceListId: '${j['price_list_id'] ?? j['price_list'] ?? 'best'}',
        groupId: j['group_id'] == null ? null : '${j['group_id']}',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price_list_id': priceListId,
        if (groupId != null) 'group_id': groupId,
      };
}

class PriceList {
  final String id;
  final String name;
  final double discountPercent;
  final Map<String, double> itemPrices;

  const PriceList({
    required this.id,
    required this.name,
    required this.discountPercent,
    this.itemPrices = const {},
  });

  double? priceFor(String itemCode) => itemPrices[itemCode];

  factory PriceList.fromJson(Map<String, dynamic> j) => PriceList(
        id: '${j['id'] ?? j['price_list_id'] ?? ''}',
        name: '${j['name'] ?? j['price_list_name'] ?? ''}',
        discountPercent: _num(j['discount_percent'] ?? j['discount'] ?? 0),
        itemPrices: ((j['item_prices'] ?? j['prices'] ?? {}) as Map)
            .map((k, v) => MapEntry('$k', _num(v))),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'discount_percent': discountPercent,
        'item_prices': itemPrices,
      };
}

class UserAccount {
  final String username;
  final String displayName;
  final String role;
  final Set<String> permissions;

  const UserAccount({
    required this.username,
    required this.displayName,
    required this.role,
    this.permissions = const <String>{},
  });

  factory UserAccount.fromJson(Map<String, dynamic> j) {
    final role = '${j['role'] ?? 'sales'}';
    return UserAccount(
      username: '${j['username'] ?? j['user'] ?? ''}',
      displayName: '${j['display_name'] ?? j['name'] ?? ''}',
      role: role,
      permissions: _permissionSet(j['permissions'], role),
    );
  }

  Map<String, dynamic> toJson() => {
        'username': username,
        'display_name': displayName,
        'role': role,
        'permissions': permissions.toList()..sort(),
      };

  bool can(String permission) {
    if (role == 'admin') return true;
    if (permissions.isEmpty && role == 'store') {
      return {'items:read', 'prices:read', 'history:read'}.contains(permission);
    }
    if (permissions.isEmpty && role == 'sales') {
      return permission.startsWith('sales:') ||
          {'items:read', 'customers:read', 'prices:read', 'history:read'}.contains(permission);
    }
    if (permissions.contains('*') || permissions.contains(permission)) return true;
    final namespace = permission.split(':').first;
    return permissions.contains('$namespace:*');
  }
}

class AuthSession {
  final String accessToken;
  final String? refreshToken;
  final DateTime? accessTokenExpiresAt;
  final UserAccount user;

  const AuthSession({
    required this.accessToken,
    required this.user,
    this.refreshToken,
    this.accessTokenExpiresAt,
  });

  bool get isExpired {
    final expires = accessTokenExpiresAt;
    if (expires == null) return false;
    return DateTime.now().isAfter(expires.subtract(const Duration(seconds: 45)));
  }

  factory AuthSession.fromJson(Map<String, dynamic> j) => AuthSession(
        accessToken: '${j['access_token'] ?? j['token'] ?? ''}',
        refreshToken: j['refresh_token'] == null ? null : '${j['refresh_token']}',
        accessTokenExpiresAt: _date(j['expires_at'] ?? j['access_token_expires_at']),
        user: UserAccount.fromJson(Map<String, dynamic>.from(j['user'] ?? {})),
      );

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        if (refreshToken != null) 'refresh_token': refreshToken,
        if (accessTokenExpiresAt != null)
          'access_token_expires_at': accessTokenExpiresAt!.toIso8601String(),
        'user': user.toJson(),
      };
}

class TicketLine {
  final String itemCode;
  final String priceListId;
  final double referencePrice;
  double qty;
  double price;

  TicketLine({
    required this.itemCode,
    required this.qty,
    required this.price,
    String? priceListId,
    double? referencePrice,
  })  : priceListId = priceListId ?? '',
        referencePrice = referencePrice ?? price;

  factory TicketLine.fromJson(Map<String, dynamic> j) => TicketLine(
        itemCode: '${j['item_code'] ?? j['id'] ?? ''}',
        qty: _num(j['qty'] ?? j['quantity'] ?? 0),
        price: _num(j['price'] ?? j['actual_price'] ?? 0),
        priceListId: '${j['price_list_id'] ?? ''}',
        referencePrice: _num(j['reference_price'] ?? j['suggested_price'] ?? j['price'] ?? 0),
      );

  Map<String, dynamic> toJson() => {
        'item_code': itemCode,
        'qty': qty,
        'price': price,
        'actual_price': price,
        'reference_price': referencePrice,
        'price_list_id': priceListId,
      };
}

class Ticket {
  final String id;
  String customerId;
  String priceListId;
  final DateTime createdAt;
  DateTime updatedAt;
  final bool localOnly;
  final List<TicketLine> lines;

  Ticket({
    required this.id,
    required this.customerId,
    required this.priceListId,
    required this.createdAt,
    DateTime? updatedAt,
    this.localOnly = false,
    List<TicketLine>? lines,
  })  : updatedAt = updatedAt ?? createdAt,
        lines = lines ?? [];

  double get total => lines.fold(0, (s, l) => s + l.qty * l.price);

  factory Ticket.fromJson(Map<String, dynamic> j) => Ticket(
        id: '${j['id'] ?? j['session_id'] ?? ''}',
        customerId: '${j['customer_id'] ?? 'CASH'}',
        priceListId: '${j['price_list_id'] ?? 'best'}',
        createdAt: _date(j['created_at']) ?? DateTime.now(),
        updatedAt: _date(j['updated_at']),
        localOnly: j['local_only'] == true,
        lines: ((j['lines'] ?? j['items'] ?? []) as List)
            .map((e) => TicketLine.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'customer_id': customerId,
        'price_list_id': priceListId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'local_only': localOnly,
        'lines': lines.map((e) => e.toJson()).toList(),
      };
}

class HistoryEntry {
  final String type;
  final String ticketId;
  final String itemCode;
  final double? qty;
  final double? price;
  final double? total;
  final String priceListId;
  final DateTime date;

  HistoryEntry({
    required this.type,
    required this.ticketId,
    this.itemCode = '',
    this.qty,
    this.price,
    this.total,
    this.priceListId = '',
    required this.date,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
        type: '${j['type'] ?? ''}',
        ticketId: '${j['ticket'] ?? j['ticket_id'] ?? ''}',
        itemCode: '${j['item'] ?? j['item_code'] ?? ''}',
        qty: j['qty'] == null ? null : _num(j['qty']),
        price: j['price'] == null ? null : _num(j['price']),
        total: j['total'] == null ? null : _num(j['total']),
        priceListId: '${j['list'] ?? j['price_list_id'] ?? ''}',
        date: _date(j['date']) ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'ticket_id': ticketId,
        'item_code': itemCode,
        'qty': qty,
        'price': price,
        'total': total,
        'price_list_id': priceListId,
        'date': date.toIso8601String(),
      };
}

class QueueOperation {
  final String id;
  final String type;
  final Map<String, dynamic> payload;
  QueueStatus status;
  int attempts;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? nextAttemptAt;
  String? error;

  QueueOperation({
    required this.id,
    required this.type,
    required this.payload,
    this.status = QueueStatus.pending,
    this.attempts = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.nextAttemptAt,
    this.error,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isDone => status == QueueStatus.acknowledged;
  bool get canRun {
    if (status == QueueStatus.acknowledged || status == QueueStatus.inFlight) return false;
    final next = nextAttemptAt;
    return next == null || !DateTime.now().isBefore(next);
  }

  factory QueueOperation.fromJson(Map<String, dynamic> j) => QueueOperation(
        id: '${j['id']}',
        type: '${j['type']}',
        payload: Map<String, dynamic>.from(j['payload'] ?? {}),
        status: queueStatusFromString('${j['status'] ?? 'pending'}'),
        attempts: (j['attempts'] is num) ? (j['attempts'] as num).toInt() : 0,
        createdAt: _date(j['created_at']),
        updatedAt: _date(j['updated_at']),
        nextAttemptAt: _date(j['next_attempt_at']),
        error: j['error'] == null ? null : '${j['error']}',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'payload': payload,
        'status': status.name,
        'attempts': attempts,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt!.toIso8601String(),
        if (error != null) 'error': error,
      };
}

double _num(dynamic x) => x is num ? x.toDouble() : double.tryParse('$x') ?? 0;

DateTime? _date(dynamic x) {
  if (x == null) return null;
  return DateTime.tryParse('$x');
}

List<String> _stringList(dynamic value) {
  if (value is List) return value.map((e) => '$e').where((e) => e.isNotEmpty).toList();
  if (value is String && value.trim().isNotEmpty) return [value.trim()];
  return const [];
}

Set<String> _permissionSet(dynamic value, String role) {
  final provided = _stringList(value).toSet();
  if (provided.isNotEmpty) return provided;
  switch (role) {
    case 'admin':
      return {'*'};
    case 'store':
      return {'items:read', 'prices:read', 'history:read'};
    default:
      return {
        'sales:*',
        'items:read',
        'customers:read',
        'prices:read',
        'history:read',
      };
  }
}
