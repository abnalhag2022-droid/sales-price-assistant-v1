import 'dart:math';

import '../models/models.dart';
import 'api_service.dart';

class SyncResult {
  final int acknowledged;
  final int failed;
  final int conflicts;
  final bool stoppedOnRetryableFailure;

  const SyncResult({
    required this.acknowledged,
    required this.failed,
    required this.conflicts,
    required this.stoppedOnRetryableFailure,
  });
}

class SyncService {
  final ApiService api;
  SyncService(this.api);

  Future<SyncResult> flush(List<QueueOperation> queue) async {
    var acknowledged = 0;
    var failed = 0;
    var conflicts = 0;
    var stopped = false;

    queue.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    for (final op in queue.where((x) => !x.isDone).toList()) {
      if (!op.canRun) continue;
      op.status = QueueStatus.inFlight;
      op.updatedAt = DateTime.now();
      try {
        await _apply(op);
        op.status = QueueStatus.acknowledged;
        op.error = null;
        op.updatedAt = DateTime.now();
        acknowledged++;
      } on ApiException catch (e) {
        op.attempts += 1;
        op.updatedAt = DateTime.now();
        op.error = e.message;
        if (e.isConflict) {
          op.status = QueueStatus.conflict;
          conflicts++;
          continue;
        }
        op.status = QueueStatus.failed;
        op.nextAttemptAt = DateTime.now().add(_backoff(op.attempts));
        failed++;
        stopped = true;
        break;
      } catch (e) {
        op.attempts += 1;
        op.updatedAt = DateTime.now();
        op.error = '$e';
        op.status = QueueStatus.failed;
        op.nextAttemptAt = DateTime.now().add(_backoff(op.attempts));
        failed++;
        stopped = true;
        break;
      }
    }

    queue.removeWhere((op) => op.status == QueueStatus.acknowledged);
    return SyncResult(
      acknowledged: acknowledged,
      failed: failed,
      conflicts: conflicts,
      stoppedOnRetryableFailure: stopped,
    );
  }

  Future<void> _apply(QueueOperation op) async {
    final p = op.payload;
    switch (op.type) {
      case 'create_session':
        await api.createSession(
          '${p['customer_id']}',
          '${p['price_list_id']}',
          clientSessionId: '${p['ticket_id']}',
          operationId: op.id,
        );
        break;
      case 'add_line':
        await api.addLine(
          '${p['ticket_id']}',
          TicketLine(
            itemCode: '${p['item_code']}',
            qty: _num(p['qty']),
            price: _num(p['price']),
            priceListId: '${p['price_list_id'] ?? ''}',
            referencePrice: _num(p['reference_price'] ?? p['price']),
          ),
          operationId: op.id,
        );
        break;
      case 'edit_line':
        await api.editLine(
          '${p['ticket_id']}',
          '${p['item_code']}',
          _num(p['qty']),
          _num(p['price']),
          operationId: op.id,
        );
        break;
      case 'delete_line':
        await api.deleteLine(
          '${p['ticket_id']}',
          '${p['item_code']}',
          operationId: op.id,
        );
        break;
      case 'complete':
        await api.complete('${p['ticket_id']}', operationId: op.id);
        break;
      case 'admin_upsert':
        await api.adminUpsert(
          '${p['resource']}',
          Map<String, dynamic>.from(p['body'] ?? {}),
          id: p['id'] == null ? null : '${p['id']}',
          operationId: op.id,
        );
        break;
      case 'admin_delete':
        await api.adminDelete(
          '${p['resource']}',
          '${p['id']}',
          operationId: op.id,
        );
        break;
      default:
        throw ApiException(400, 'نوع عملية مزامنة غير معروف: ${op.type}');
    }
  }

  Duration _backoff(int attempts) {
    final capped = min(attempts, 6);
    return Duration(seconds: min(300, pow(2, capped).toInt() * 5));
  }
}

double _num(dynamic x) => x is num ? x.toDouble() : double.tryParse('$x') ?? 0;
