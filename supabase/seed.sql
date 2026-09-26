-- ==============================================================================
-- seed.sql
-- Production baseline fixtures: Industrial Cable Factory Machines (Lines 1 to 7)
-- ===============================================================================

-- Reference data is intentionally idempotent. Auth users are created/invited in Supabase Auth;
-- never put passwords or fabricated auth.users UUIDs in a committed seed file.
INSERT INTO public.factory_departments (code, name_en, name_ar) VALUES
  ('drawing', 'Drawing', 'السحب'),
  ('ccv', 'CCV Insulation', 'العزل والتكسية'),
  ('stranding', 'Stranding', 'الجدل'),
  ('tapeArmour', 'Tape Armouring', 'التسليح'),
  ('extrusion', 'Extrusion', 'الغلاف الخارجي'),
  ('assembly', 'Assembly & Rewinding', 'إعادة لف'),
  ('screening', 'Screening', 'التجهيز')
ON CONFLICT (code) DO UPDATE SET name_en = EXCLUDED.name_en, name_ar = EXCLUDED.name_ar;

INSERT INTO public.factory_roles (code, name_en, name_ar, web_access) VALUES
  ('ADMIN', 'Administrator', 'مدير النظام', TRUE),
  ('SUPERVISOR', 'Maintenance Supervisor', 'مشرف صيانة', TRUE),
  ('PRODUCTION_SUPERVISOR', 'Production Supervisor', 'مشرف إنتاج', TRUE),
  ('TECHNICIAN', 'Technician', 'فني', FALSE),
  ('OPERATOR', 'Operator', 'مشغل', FALSE)
ON CONFLICT (code) DO UPDATE SET name_en = EXCLUDED.name_en, name_ar = EXCLUDED.name_ar, web_access = EXCLUDED.web_access;

INSERT INTO public.spare_parts (part_code, name, description, unit, quantity_on_hand, reorder_level) VALUES
  ('BRG-6205-2RS', 'Deep groove ball bearing 6205-2RS', 'Sealed radial bearing for rotating equipment', 'piece', 12, 4),
  ('BELT-SPB-1600', 'SPB drive belt 1600 mm', 'Industrial V-belt for line drive', 'piece', 8, 3),
  ('SENS-IND-M18', 'Inductive proximity sensor M18', '24V DC machine position sensor', 'piece', 10, 3),
  ('FUSE-10A-GG', 'Industrial fuse 10A gG', 'Control cabinet replacement fuse', 'piece', 20, 6)
ON CONFLICT (part_code) DO UPDATE SET
  name = EXCLUDED.name, description = EXCLUDED.description, unit = EXCLUDED.unit,
  reorder_level = EXCLUDED.reorder_level;

INSERT INTO public.machines (id, code, name, department, status, sub_category, current_speed_mpm, total_meters_produced)
VALUES
  -- 1. Drawing Department (drawing)
  ('DR01', 'DR01', 'Copper Drawing Line 01', 'drawing', 'running', 'Copper Drawing', 1200.0, 450000.0),
  ('DR02', 'DR02', 'Copper Drawing Line 02', 'drawing', 'running', 'Copper Drawing', 1150.0, 420000.0),
  ('DR03', 'DR03', 'Copper Drawing Line 03', 'drawing', 'idle', 'Copper Drawing', 0.0, 390000.0),
  ('DR04', 'DR04', 'Aluminum & Al-Alloy Drawing 01', 'drawing', 'running', 'Aluminum & Al-Alloy Drawing', 950.0, 310000.0),
  ('DR05', 'DR05', 'Aluminum & Al-Alloy Drawing 02', 'drawing', 'running', 'Aluminum & Al-Alloy Drawing', 980.0, 330000.0),
  ('DR06', 'DR06', 'Copper Multiwire 14-Wire Line 01', 'drawing', 'running', 'Copper Multiwire (14 wires)', 1500.0, 890000.0),
  ('DR07', 'DR07', 'Copper Multiwire 14-Wire Line 02', 'drawing', 'running', 'Copper Multiwire (14 wires)', 1550.0, 920000.0),

  -- 2. Stranding & Bunching Department (stranding)
  ('RS01', 'RS01', 'Rigid Strander 61 - Line 01', 'stranding', 'running', 'Rigid Strander 61', 180.0, 125000.0),
  ('RS02', 'RS02', 'Rigid Strander 61 - Line 02', 'stranding', 'running', 'Rigid Strander 61', 175.0, 118000.0),
  ('RS03', 'RS03', 'Rigid Strander 61 - Line 03', 'stranding', 'running', 'Rigid Strander 61', 185.0, 130000.0),
  ('RS04', 'RS04', 'Rigid Strander 61 - Line 04', 'stranding', 'downtimeMaintenance', 'Rigid Strander 61', 0.0, 95000.0),
  ('CS01', 'CS01', 'Circular/Cage Strander 37 - Line 01', 'stranding', 'running', 'Circular/Cage Strander 37', 220.0, 210000.0),
  ('CS02', 'CS02', 'Circular/Cage Strander 37 - Line 02', 'stranding', 'running', 'Circular/Cage Strander 37', 215.0, 205000.0),
  ('RS05', 'RS05', 'Rigid Strander 19 - Line 05', 'stranding', 'running', 'Rigid Strander 19', 280.0, 340000.0),
  ('DTS01', 'DTS01', 'Double Twist Strander 7 - Line 01', 'stranding', 'running', 'Double Twist Strander 7', 450.0, 560000.0),
  ('BN01', 'BN01', 'Buncher 630 - Line 01', 'stranding', 'running', 'Buncher (630)', 350.0, 410000.0),
  ('BN02', 'BN02', 'Buncher 630 - Line 02', 'stranding', 'running', 'Buncher (630)', 360.0, 420000.0),
  ('BN03', 'BN03', 'Buncher 630 - Line 03', 'stranding', 'running', 'Buncher (630)', 355.0, 415000.0),
  ('BN04', 'BN04', 'Buncher 630 - Line 04', 'stranding', 'running', 'Buncher (630)', 345.0, 395000.0),
  ('BN05', 'BN05', 'Buncher 630 - Line 05', 'stranding', 'running', 'Buncher (630)', 350.0, 400000.0),
  ('BN06', 'BN06', 'Buncher 800 - Line 06', 'stranding', 'running', 'Buncher (800)', 300.0, 380000.0),
  ('BN07', 'BN07', 'Buncher 800 - Line 07', 'stranding', 'running', 'Buncher (800)', 310.0, 390000.0),
  ('BN08', 'BN08', 'Buncher 800 - Line 08', 'stranding', 'running', 'Buncher (800)', 305.0, 385000.0),

  -- 3. CCV Lines (ccv)
  ('CCV01', 'CCV01', 'Medium/High Voltage CCV Line 01 (500kV)', 'ccv', 'running', 'CCV Line (Up to 500kV)', 25.0, 85000.0),
  ('CCV02', 'CCV02', 'Medium/High Voltage CCV Line 02 (500kV)', 'ccv', 'running', 'CCV Line (Up to 500kV)', 28.0, 92000.0),
  ('CCV03', 'CCV03', 'Extra High Voltage CCV Line 03 (750kV)', 'ccv', 'running', 'CCV Line (Up to 750kV)', 18.0, 64000.0),
  ('CCV04', 'CCV04', 'Extra High Voltage CCV Line 04 (750kV)', 'ccv', 'downtimeProcess', 'CCV Line (Up to 750kV)', 0.0, 58000.0),
  ('CCV05', 'CCV05', 'Medium Voltage CCV Line 05', 'ccv', 'running', 'CCV Line (Medium Voltage)', 32.0, 110000.0),

  -- 4. Extrusion Department (extrusion)
  ('EX01', 'EX01', 'LV Extrusion Line 01 (Insulation)', 'extrusion', 'running', 'Low Voltage Extrusion', 450.0, 780000.0),
  ('EX02', 'EX02', 'LV Extrusion Line 02 (Insulation)', 'extrusion', 'running', 'Low Voltage Extrusion', 460.0, 810000.0),
  ('EX03', 'EX03', 'LV Extrusion Line 03 (Bedding)', 'extrusion', 'running', 'Low Voltage Extrusion', 420.0, 740000.0),
  ('EX04', 'EX04', 'LV Extrusion Line 04 (Jacketing)', 'extrusion', 'running', 'Low Voltage Extrusion', 380.0, 690000.0),
  ('EX05', 'EX05', 'LV Extrusion Line 05 (Jacketing)', 'extrusion', 'running', 'Low Voltage Extrusion', 390.0, 710000.0),
  ('EX06', 'EX06', 'LV Extrusion Line 06 (Insulation)', 'extrusion', 'running', 'Low Voltage Extrusion', 440.0, 760000.0),
  ('EX07', 'EX07', 'LV Extrusion Line 07 (Insulation)', 'extrusion', 'running', 'Low Voltage Extrusion', 430.0, 750000.0),
  ('EX08', 'EX08', 'LV Extrusion Line 08 (Bedding)', 'extrusion', 'running', 'Low Voltage Extrusion', 410.0, 720000.0),
  ('EX09', 'EX09', 'LV Extrusion Line 09 (Bedding)', 'extrusion', 'running', 'Low Voltage Extrusion', 415.0, 730000.0),
  ('EX10', 'EX10', 'LV Extrusion Line 10 (Jacketing)', 'extrusion', 'running', 'Low Voltage Extrusion', 375.0, 680000.0),
  ('EX11', 'EX11', 'LV Extrusion Line 11 (Jacketing)', 'extrusion', 'running', 'Low Voltage Extrusion', 385.0, 700000.0),

  -- 5. Assembly & Wire Armouring Department (assembly)
  ('DT01', 'DT01', 'Drum Twister DT-3000', 'assembly', 'running', 'Drum Twister', 45.0, 180000.0),
  ('DT02', 'DT02', 'Drum Twister DT-3600', 'assembly', 'running', 'Drum Twister', 40.0, 165000.0),
  ('DT03', 'DT03', 'Drum Twister DT-4000', 'assembly', 'running', 'Drum Twister', 35.0, 140000.0),
  ('DT04', 'DT04', 'Drum Twister DT-3200', 'assembly', 'running', 'Drum Twister', 42.0, 172000.0),
  ('BW01', 'BW01', 'Bow Cabling Line 01', 'assembly', 'running', 'Bow Cabling', 120.0, 290000.0),

  -- 6. Screening & Taping Department (screening)
  ('CT01', 'CT01', 'Copper Tape Line 01', 'screening', 'running', 'Copper Tape / Mica / PPT', 160.0, 310000.0),
  ('CT02', 'CT02', 'Copper Tape Line 02', 'screening', 'running', 'Copper Tape / Mica / PPT', 165.0, 325000.0),
  ('CT03', 'CT03', 'Copper Tape Line 03', 'screening', 'running', 'Copper Tape / Mica / PPT', 155.0, 295000.0),
  ('CW01', 'CW01', 'Copper Wire Screen Line 01', 'screening', 'running', 'Copper Wire Screen', 110.0, 240000.0),
  ('CW02', 'CW02', 'Copper Wire Screen Line 02', 'screening', 'running', 'Copper Wire Screen', 115.0, 250000.0),
  ('CW03', 'CW03', 'Copper Wire Screen Line 03', 'screening', 'running', 'Copper Wire Screen', 108.0, 235000.0),

  -- 7. Tape Armouring Department (tapeArmour)
  ('ST01', 'ST01', 'Steel Tape Armouring Line 01', 'tapeArmour', 'running', 'Steel Tape Armouring', 140.0, 280000.0),
  ('ST02', 'ST02', 'Steel Tape Armouring Line 02', 'tapeArmour', 'running', 'Steel Tape Armouring', 145.0, 290000.0),
  ('ST03', 'ST03', 'Steel Tape Armouring Line 03', 'tapeArmour', 'running', 'Steel Tape Armouring', 138.0, 275000.0),
  ('ST04', 'ST04', 'Steel Tape Armouring Line 04', 'tapeArmour', 'running', 'Steel Tape Armouring', 142.0, 285000.0)

ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  department = EXCLUDED.department,
  sub_category = EXCLUDED.sub_category,
  updated_at = NOW();

-- EX01 is the stable machine id/code already used by mobile and demo records;
-- it represents the extrusion line commonly shown as EX-01 in business documents.
INSERT INTO public.machine_bom (machine_id, spare_part_id, quantity_per_machine)
SELECT 'EX01', id, 1 FROM public.spare_parts WHERE part_code IN ('BRG-6205-2RS', 'BELT-SPB-1600', 'SENS-IND-M18')
ON CONFLICT (machine_id, spare_part_id) DO UPDATE
SET quantity_per_machine = EXCLUDED.quantity_per_machine;
