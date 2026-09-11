import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

class AccentPalette extends Equatable {
  final String id;
  final String nameAr;
  final String nameEn;
  final Color primary;
  final Color secondary;

  const AccentPalette({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.primary,
    required this.secondary,
  });

  @override
  List<Object?> get props => [id, primary, secondary];
}

class AppPalettes {
  static const energyaOfficial = AccentPalette(
    id: 'energya_official',
    nameAr: 'إنرجيا كابلز (Energya Official)',
    nameEn: 'Energya Cables (Official)',
    primary: Color(0xFF0C4595),
    secondary: Color(0xFFF04E37),
  );

  static const cyberElectric = AccentPalette(
    id: 'cyber_electric',
    nameAr: 'أزرق كهربائي (Cyber Electric)',
    nameEn: 'Cyber Electric Blue',
    primary: Color(0xFF2563EB),
    secondary: Color(0xFF06B6D4),
  );

  static const emeraldFactory = AccentPalette(
    id: 'emerald_factory',
    nameAr: 'زمرد صناعي (Emerald Green)',
    nameEn: 'Industrial Emerald',
    primary: Color(0xFF059669),
    secondary: Color(0xFF10B981),
  );

  static const amberHeavy = AccentPalette(
    id: 'amber_heavy',
    nameAr: 'كهرماني ثقيل (Amber Gold)',
    nameEn: 'Industrial Amber',
    primary: Color(0xFFD97706),
    secondary: Color(0xFFF59E0B),
  );

  static const neonViolet = AccentPalette(
    id: 'neon_violet',
    nameAr: 'بنفسجي نيون (Neon Violet)',
    nameEn: 'Neon Violet',
    primary: Color(0xFF7C3AED),
    secondary: Color(0xFFA78BFA),
  );

  static const extrusionOrange = AccentPalette(
    id: 'extrusion_orange',
    nameAr: 'برتقالي العزل (Extrusion Flame)',
    nameEn: 'Extrusion Orange',
    primary: Color(0xFFEA580C),
    secondary: Color(0xFFFB923C),
  );

  static const crimsonSafety = AccentPalette(
    id: 'crimson_safety',
    nameAr: 'أحمر السلامة (Safety Crimson)',
    nameEn: 'Safety Crimson',
    primary: Color(0xFFDC2626),
    secondary: Color(0xFFF87171),
  );

  static const List<AccentPalette> allPalettes = [
    energyaOfficial,
    cyberElectric,
    emeraldFactory,
    amberHeavy,
    neonViolet,
    extrusionOrange,
    crimsonSafety,
  ];

  static AccentPalette findById(String id) {
    return allPalettes.firstWhere(
      (p) => p.id == id,
      orElse: () => energyaOfficial,
    );
  }
}
