import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Production Readiness & Security Audit Test Suite', () {
    test('lib/ contains zero occurrences of service_role key or pattern', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue);

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final violations = <String>[];

      for (final file in dartFiles) {
        final content = file.readAsStringSync().toLowerCase();
        if (content.contains('service_role')) {
          violations.add(file.path);
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Security violation: service_role key found in client source code: $violations',
      );
    });

    test('active migrations and client code contain zero production password leaks', () {
      final scanDirs = [
        Directory('lib'),
        Directory('supabase/migrations'),
        Directory('supabase/migrations_down'),
      ];
      final violations = <String>[];

      for (final dir in scanDirs) {
        if (!dir.existsSync()) continue;
        final files = dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart') || f.path.endsWith('.sql'));

        for (final file in files) {
          final content = file.readAsStringSync();
          if (content.contains('Cable@2026!')) {
            violations.add('${file.path} contains leaked production password: Cable@2026!');
          }
          if (file.path.contains('migrations') && content.contains('123456')) {
            violations.add('${file.path} contains plaintext password: 123456');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Found hardcoded credentials in codebase: $violations',
      );
    });

    test('1:1 symmetry between migrations and down-migrations (1 through 8)', () {
      final forwardDir = Directory('supabase/migrations');
      final downDir = Directory('supabase/migrations_down');

      expect(forwardDir.existsSync(), isTrue);
      expect(downDir.existsSync(), isTrue);

      final forwardFiles = forwardDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.sql'))
          .map((f) => f.uri.pathSegments.last)
          .toList()
        ..sort();

      expect(forwardFiles.length, greaterThanOrEqualTo(8));

      for (final forwardName in forwardFiles) {
        final baseName = forwardName.replaceAll('.sql', '');
        final expectedDownName = '$baseName.down.sql';
        final downFile = File('${downDir.path}/$expectedDownName');

        expect(
          downFile.existsSync(),
          isTrue,
          reason: 'Missing rollback migration: $expectedDownName for $forwardName',
        );
      }
    });

    test('All Phase 4 created/modified Dart files strictly comply with <= 250 lines', () {
      final phase4Files = [
        'lib/core/storage/attachment_service.dart',
        'lib/core/sync/outbox/outbox_sync_engine.dart',
        'lib/core/di/service_locator.dart',
        'test/storage_attachment_security_test.dart',
        'test/rate_limiting_resilience_test.dart',
        'test/production_readiness_audit_test.dart',
      ];

      final overLimit = <String, int>{};

      for (final path in phase4Files) {
        final file = File(path);
        if (!file.existsSync()) continue;
        final lines = file.readAsLinesSync().length;
        if (lines > 250) {
          overLimit[path] = lines;
        }
      }

      expect(
        overLimit,
        isEmpty,
        reason: 'Files exceeding 250 lines limit: $overLimit',
      );
    });
  });
}
