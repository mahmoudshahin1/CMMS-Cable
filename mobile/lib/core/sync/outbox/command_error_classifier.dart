import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'outbox_command.dart';

/// Semantic classification of outbox command dispatch failures.
enum CommandFailureType {
  retryableTransport,
  retryableRateLimit,
  terminalConflict, // 40001
  terminalUnauthorized, // 42501
  terminalIllegalState, // P0001
  terminalNotFound, // P0002
  terminalConstraint, // 22P02, 23502, 23503, etc.
  terminalOther,
}

/// Structured outcome of classifying an error.
class CommandClassification {
  final CommandFailureType type;
  final bool isRetryable;
  final OutboxCommandStatus terminalStatus;
  final String userMessageEn;
  final String userMessageAr;

  const CommandClassification({
    required this.type,
    required this.isRetryable,
    required this.terminalStatus,
    required this.userMessageEn,
    required this.userMessageAr,
  });

  String get localizedMessage => userMessageEn;
}

/// Classifies RPC / transport failures into retryable vs. terminal rejections.
class CommandErrorClassifier {
  static const Set<String> _terminalCodes = {
    '40001', // Version conflict / serialization failure
    '42501', // Insufficient privilege / unauthorized
    'P0001', // Raise exception / illegal state transition
    'P0002', // No data found / work order not found
    '22P02', // Invalid text representation (UUID syntax error)
    '23502', // Not null violation
    '23503', // Foreign key violation
    '23505', // Unique violation
    '23514', // Check constraint violation
  };

  static CommandClassification classify(Object error) {
    if (isRateLimited(error)) {
      return const CommandClassification(
        type: CommandFailureType.retryableRateLimit,
        isRetryable: true,
        terminalStatus: OutboxCommandStatus.failed,
        userMessageEn: 'Rate limit exceeded. Retrying shortly...',
        userMessageAr: 'تم تجاوز معدل الطلبات. ستتم إعادة المحاولة قريباً...',
      );
    }

    final code = extractErrorCode(error);
    final str = error.toString().toLowerCase();

    // 1. Version conflict (40001)
    if (code == '40001' ||
        str.contains('40001') ||
        str.contains('version conflict') ||
        str.contains('version_mismatch')) {
      return const CommandClassification(
        type: CommandFailureType.terminalConflict,
        isRetryable: false,
        terminalStatus: OutboxCommandStatus.failedConflict,
        userMessageEn: 'This work order was already updated by someone else.',
        userMessageAr: 'تم تحديث أمر العمل هذا بالفعل من قبل مستخدم آخر.',
      );
    }

    // 2. Unauthorized / Forbidden (42501)
    if (code == '42501' ||
        str.contains('42501') ||
        str.contains('unauthorized') ||
        str.contains('forbidden') ||
        str.contains('not assigned')) {
      return const CommandClassification(
        type: CommandFailureType.terminalUnauthorized,
        isRetryable: false,
        terminalStatus: OutboxCommandStatus.failedRejected,
        userMessageEn: 'You are not assigned to this ticket or lack permission.',
        userMessageAr: 'لست الفني المعين لهذا التذكرة أو لا تملك الصلاحية.',
      );
    }

    // 3. Illegal state transition (P0001)
    if (code == 'P0001' ||
        str.contains('p0001') ||
        str.contains('illegal state') ||
        str.contains('invalid state') ||
        str.contains('invalid_transition')) {
      return const CommandClassification(
        type: CommandFailureType.terminalIllegalState,
        isRetryable: false,
        terminalStatus: OutboxCommandStatus.failedRejected,
        userMessageEn:
            'This work order is no longer in a state where this action is possible.',
        userMessageAr: 'أمر العمل لم يعد في حالة تسمح بهذا الإجراء.',
      );
    }

    // 4. Not found (P0002)
    if (code == 'P0002' ||
        str.contains('p0002') ||
        str.contains('not found') ||
        str.contains('work order not found')) {
      return const CommandClassification(
        type: CommandFailureType.terminalNotFound,
        isRetryable: false,
        terminalStatus: OutboxCommandStatus.failedRejected,
        userMessageEn: 'This work order was not found on the server.',
        userMessageAr: 'لم يتم العثور على أمر العمل هذا في الخادم.',
      );
    }

    // 5. Schema / constraint errors
    if ((code != null && _terminalCodes.contains(code)) ||
        str.contains('22p02') ||
        str.contains('23502') ||
        str.contains('23503') ||
        str.contains('23505') ||
        str.contains('23514')) {
      return const CommandClassification(
        type: CommandFailureType.terminalConstraint,
        isRetryable: false,
        terminalStatus: OutboxCommandStatus.failedRejected,
        userMessageEn: 'Data constraint error: rejected by server.',
        userMessageAr: 'خطأ في قيود البيانات: تم رفض الطلب من الخادم.',
      );
    }

    // 6. Generic PostgrestException with application error code
    if (error is PostgrestException) {
      final c = error.code ?? '';
      if (c.isNotEmpty && !c.startsWith('5')) {
        return CommandClassification(
          type: CommandFailureType.terminalOther,
          isRetryable: false,
          terminalStatus: OutboxCommandStatus.failedRejected,
          userMessageEn: 'Server rejected command: ${error.message}',
          userMessageAr: 'رفض الخادم الأمر: ${error.message}',
        );
      }
    }

    // 7. Retryable transport errors
    if (error is SocketException ||
        error is TimeoutException ||
        error is HttpException ||
        str.contains('socketexception') ||
        str.contains('connection refused') ||
        str.contains('connection closed') ||
        str.contains('connection reset') ||
        str.contains('network is unreachable') ||
        str.contains('handshake failed') ||
        str.contains('failed host lookup') ||
        str.contains('500') ||
        str.contains('502') ||
        str.contains('503') ||
        str.contains('504')) {
      return const CommandClassification(
        type: CommandFailureType.retryableTransport,
        isRetryable: true,
        terminalStatus: OutboxCommandStatus.failed,
        userMessageEn: 'Network error. Will retry automatically.',
        userMessageAr: 'خطأ في الشبكة. ستتم إعادة المحاولة تلقائياً.',
      );
    }

    if (code != null && code.isNotEmpty) {
      return CommandClassification(
        type: CommandFailureType.terminalOther,
        isRetryable: false,
        terminalStatus: OutboxCommandStatus.failedRejected,
        userMessageEn: 'Command rejected ($code).',
        userMessageAr: 'تم رفض الأمر ($code).',
      );
    }

    return const CommandClassification(
      type: CommandFailureType.retryableTransport,
      isRetryable: true,
      terminalStatus: OutboxCommandStatus.failed,
      userMessageEn: 'Connection error. Retrying...',
      userMessageAr: 'خطأ في الاتصال. جاري إعادة المحاولة...',
    );
  }

  static String? extractErrorCode(Object error) {
    if (error is PostgrestException) {
      return error.code;
    }
    final match = RegExp(
      r'\b(40001|42501|P0001|P0002|22P02|23502|23503|23505|23514|P0429)\b',
      caseSensitive: false,
    ).firstMatch(error.toString());
    return match?.group(1)?.toUpperCase();
  }

  static bool isRateLimited(Object error) {
    if (error is PostgrestException) {
      final code = error.code ?? '';
      final msg = error.message.toUpperCase();
      if (code == 'P0429' || code == '429' || msg.contains('RATE_LIMIT')) {
        return true;
      }
    }
    final str = error.toString().toUpperCase();
    return str.contains('P0429') ||
        str.contains('RATE_LIMIT') ||
        str.contains('429');
  }

  static bool isTerminal(Object error) => !classify(error).isRetryable;
  static bool isRetryable(Object error) => classify(error).isRetryable;
}
