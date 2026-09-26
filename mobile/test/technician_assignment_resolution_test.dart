import 'package:flutter_test/flutter_test.dart';
import 'package:orning_and_evening_remembrances/core/auth/user_directory_helper.dart';
import 'package:orning_and_evening_remembrances/core/seed/factory_seed_data.dart';
import 'package:orning_and_evening_remembrances/features/auth/data/mock_users.dart';
import 'package:orning_and_evening_remembrances/features/auth/domain/enums/user_role.dart';
import 'package:orning_and_evening_remembrances/features/auth/domain/models/user_model.dart';

void main() {
  group('Technician Assignment & Resolution Tests', () {
    test('MockUsers has electrical and mechanical technicians', () {
      expect(MockUsers.electricalTech.role, UserRole.maintenanceTech);
      expect(MockUsers.electricalTech.speciality, 'Electrical');

      expect(MockUsers.mechanicalTech.role, UserRole.maintenanceTech);
      expect(MockUsers.mechanicalTech.speciality, 'Mechanical');
    });

    test('MockUsers.getTechnicians filters by speciality accurately', () {
      final allTechs = MockUsers.getTechnicians();
      expect(allTechs.length, greaterThanOrEqualTo(2));
      expect(allTechs.any((u) => u.id == MockUsers.electricalTech.id), isTrue);
      expect(allTechs.any((u) => u.id == MockUsers.mechanicalTech.id), isTrue);

      final elecTechs = MockUsers.getTechnicians(speciality: 'Electrical');
      expect(elecTechs.isNotEmpty, isTrue);
      expect(elecTechs.every((u) => (u.speciality ?? '').toLowerCase().contains('electrical')), isTrue);

      final mechTechs = MockUsers.getTechnicians(speciality: 'Mechanical');
      expect(mechTechs.isNotEmpty, isTrue);
      expect(mechTechs.every((u) => (u.speciality ?? '').toLowerCase().contains('mechanical')), isTrue);
    });

    test('FactorySeedData includes all mock users including technicians', () {
      final seedUsers = FactorySeedData.getInitialUsers();
      expect(seedUsers.isNotEmpty, isTrue);
      expect(seedUsers.any((u) => u.id == MockUsers.electricalTech.id), isTrue);
      expect(seedUsers.any((u) => u.id == MockUsers.mechanicalTech.id), isTrue);
    });

    test('UserModel.fromSupabaseProfile handles flexible specialty & name keys', () {
      final techProfile = {
        'id': 'tech-uuid-123',
        'full_name': 'طارق المنصور - فني كهرباء',
        'role': 'TECHNICIAN',
        'specialty': 'Electrical',
        'employee_code': 'EMP-004',
      };

      final user = UserModel.fromSupabaseProfile(techProfile, email: 'tech.elec@cable.com');
      expect(user.id, 'tech-uuid-123');
      expect(user.name, 'طارق المنصور - فني كهرباء');
      expect(user.role, UserRole.maintenanceTech);
      expect(user.speciality, 'Electrical');
    });

    test('UserDirectoryHelper resolves known technician UUIDs', () {
      expect(UserDirectoryHelper.resolveName('usr-tech-elec-02'), contains('طارق المنصور'));
      expect(UserDirectoryHelper.resolveName('usr-tech-mech-03'), contains('سمير فوزي'));
      expect(UserDirectoryHelper.resolveName('cc9f6212-bf05-4610-b8a5-64f911565f37'), contains('طارق المنصور'));
      expect(UserDirectoryHelper.resolveName('90e23813-fe01-4796-8138-61f17275f432'), contains('سمير فوزي'));
    });
  });
}
