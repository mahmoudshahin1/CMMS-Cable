import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:orning_and_evening_remembrances/core/database/hive_boxes.dart';
import 'package:orning_and_evening_remembrances/core/database/adapters/enum_adapters.dart';
import 'package:orning_and_evening_remembrances/core/database/adapters/user_model_adapter.dart';
import 'package:orning_and_evening_remembrances/core/auth/user_directory_helper.dart';
import 'package:orning_and_evening_remembrances/core/seed/factory_seed_data.dart';
import 'package:orning_and_evening_remembrances/features/auth/domain/models/user_model.dart';
import 'package:orning_and_evening_remembrances/features/auth/domain/enums/user_role.dart';
import 'package:orning_and_evening_remembrances/features/work_orders/data/datasources/work_order_remote_mapper.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_test_identity_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserRoleAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(DepartmentTypeAdapter());
    }
    if (!Hive.isBoxOpen(HiveBoxes.usersBox)) {
      await Hive.openBox<UserModel>(HiveBoxes.usersBox);
    }
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Offline Technician Identity & Hive Persistence Tests', () {
    test('FactorySeedData provides provisioned technicians with real UUIDs', () {
      final initialUsers = FactorySeedData.getInitialUsers();
      final elecTech = initialUsers.firstWhere(
        (u) => u.id == 'cc9f6212-bf05-4610-b8a5-64f911565f37',
      );
      final mechTech = initialUsers.firstWhere(
        (u) => u.id == '90e23813-fe01-4796-8138-61f17275f432',
      );

      expect(elecTech.name, contains('طارق المنصور'));
      expect(elecTech.role, equals(UserRole.maintenanceTech));
      expect(mechTech.name, contains('سمير فوزي'));
      expect(mechTech.role, equals(UserRole.maintenanceTech));
    });

    test('UserDirectoryHelper automatically persists registered user to Hive usersBox', () {
      const customTech = UserModel(
        id: '12345678-1234-1234-1234-123456789abc',
        name: 'أحمد فوزي - فني كهرباء',
        email: 'ahmed.fawzy@cableops.com',
        role: UserRole.maintenanceTech,
      );

      UserDirectoryHelper.registerUser(customTech);

      // Verify in-memory lookup
      expect(UserDirectoryHelper.resolveName(customTech.id), equals('أحمد فوزي - فني كهرباء'));

      // Verify Hive box persistence
      final box = Hive.box<UserModel>(HiveBoxes.usersBox);
      final fromHive = box.get(customTech.id);
      expect(fromHive, isNotNull);
      expect(fromHive!.name, equals('أحمد فوزي - فني كهرباء'));
      expect(fromHive.role, equals(UserRole.maintenanceTech));

      // Verify getUser resolution
      final retrievedUser = UserDirectoryHelper.getUser(customTech.id);
      expect(retrievedUser, isNotNull);
      expect(retrievedUser!.email, equals('ahmed.fawzy@cableops.com'));
    });

    test('WorkOrderRemoteMapper resolves actor_id from Supabase events row to real technician name and role', () {
      const techUuid = 'cc9f6212-bf05-4610-b8a5-64f911565f37';
      const tech = UserModel(
        id: techUuid,
        name: 'طارق المنصور - فني كهرباء وتحكم',
        email: 'tech.elec@cable.com',
        role: UserRole.maintenanceTech,
      );
      UserDirectoryHelper.registerUser(tech);

      final row = {
        'id': 'evt-101',
        'event_type': 'REPAIR_COMPLETED',
        'actor_id': techUuid,
        'occurred_at': '2026-09-24T10:00:00Z',
        'payload': {
          'root_cause': 'Short circuit in drive inverter',
          'actions_taken': 'Replaced fuse and tested motor',
        },
      };

      final activityLog = WorkOrderRemoteMapper.activityLogFromRow(row);

      expect(activityLog.performedByName, equals('طارق المنصور - فني كهرباء وتحكم'));
      expect(activityLog.performedByEmail, equals('tech.elec@cable.com'));
      expect(activityLog.performedByRole, equals('MAINTENANCE_TECH'));
      expect(activityLog.performedByName, isNot(equals('System User')));
    });

    test('WorkOrderRemoteMapper infers role appropriately when actor_role is missing', () {
      final supervisorRow = {
        'id': 'evt-102',
        'event_type': 'CLOSED',
        'actor_id': 'c79d06f1-09b2-4d01-99e9-0c8fced1e56b',
        'occurred_at': '2026-09-24T11:00:00Z',
        'payload': <String, dynamic>{},
      };

      final log = WorkOrderRemoteMapper.activityLogFromRow(supervisorRow);
      expect(log.performedByName, contains('م. هشام راضي'));
      expect(log.performedByRole, equals('MAINTENANCE_SUPERVISOR'));
    });
  });
}
