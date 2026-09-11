import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/machine_model.dart';
import '../../domain/enums/department_type.dart';
import '../../domain/enums/machine_status.dart';
import '../cubit/machine_cubit.dart';
import '../cubit/machine_state.dart';
import '../widgets/scanned_machine_sheet.dart';
import '../../../../core/localization/app_strings.dart';

class QrMachineScannerScreen extends StatefulWidget {
  const QrMachineScannerScreen({super.key});

  @override
  State<QrMachineScannerScreen> createState() => _QrMachineScannerScreenState();
}

class _QrMachineScannerScreenState extends State<QrMachineScannerScreen>
    with SingleTickerProviderStateMixin {
  MobileScannerController? _scannerController;
  late final AnimationController _laserController;
  final TextEditingController _manualInputController = TextEditingController();

  bool _isProcessingCode = false;
  bool _isTorchOn = false;

  bool get _isCameraSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    if (_isCameraSupported) {
      try {
        _scannerController = MobileScannerController(
          detectionSpeed: DetectionSpeed.normal,
          facing: CameraFacing.back,
          torchEnabled: false,
        );
      } catch (_) {
        _scannerController = null;
      }
    }

    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _laserController.dispose();
    _manualInputController.dispose();
    super.dispose();
  }

  void _handleCodeDetected(String rawCode) {
    if (_isProcessingCode) return;
    final trimmed = rawCode.trim();
    if (trimmed.isEmpty) return;

    setState(() => _isProcessingCode = true);

    final machineState = context.read<MachineCubit>().state;
    List<MachineModel> allMachines = [];
    if (machineState is MachineLoaded) {
      allMachines = machineState.allMachines;
    }

    final matched = allMachines.firstWhere(
      (m) =>
          m.code.toLowerCase() == trimmed.toLowerCase() ||
          m.id.toLowerCase() == trimmed.toLowerCase(),
      orElse: () => allMachines.firstWhere(
        (m) => m.name.toLowerCase().contains(trimmed.toLowerCase()),
        orElse: () => const MachineModel(
          id: '',
          code: '',
          name: '',
          department: DepartmentType.drawing,
          status: MachineStatus.running,
          subCategory: '',
        ),
      ),
    );

    if (matched.code.isNotEmpty) {
      // Machine successfully identified!
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ScannedMachineSheet(machine: matched),
      ).whenComplete(() {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) setState(() => _isProcessingCode = false);
        });
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.trArgs('machine_not_found_snack', {'code': trimmed})),
          backgroundColor: AppColors.downMaintenanceRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _isProcessingCode = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCamera = _isCameraSupported && _scannerController != null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          context.tr('qr_scanner_title'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (hasCamera) ...[
            IconButton(
              icon: Icon(
                _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                color: _isTorchOn ? AppColors.idleAmber : Colors.white70,
              ),
              tooltip: context.tr('flash_toggle_tooltip'),
              onPressed: () async {
                await _scannerController?.toggleTorch();
                setState(() => _isTorchOn = !_isTorchOn);
              },
            ),
            IconButton(
              icon: const Icon(Icons.flip_camera_ios_rounded,
                  color: Colors.white70),
              tooltip: context.tr('camera_toggle_tooltip'),
              onPressed: () => _scannerController?.switchCamera(),
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          // 1. Camera Viewfinder (or Desktop Fallback)
          if (hasCamera)
            MobileScanner(
              controller: _scannerController!,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  final rawVal = barcode.rawValue;
                  if (rawVal != null && rawVal.isNotEmpty) {
                    _handleCodeDetected(rawVal);
                    break;
                  }
                }
              },
              errorBuilder: (context, error) {
                return _buildNoCameraFallback();
              },
            )
          else
            _buildNoCameraFallback(),

          // 2. Industrial Reticle & Laser Overlay
          _buildReticleOverlay(),

          // 3. Quick Simulation & Manual Input Sheet at Bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomLookupPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoCameraFallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.slateCard,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.slateBorder),
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                size: 56,
                color: AppColors.cyberCyan,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('industrial_scanner_ready'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr('scanner_instruction'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReticleOverlay() {
    return IgnorePointer(
      child: Center(
        child: SizedBox(
          width: 260,
          height: 260,
          child: Stack(
            children: [
              // 4 Corner Brackets
              Positioned(
                top: 0,
                left: 0,
                child: _buildCorner(isTop: true, isLeft: true),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: _buildCorner(isTop: true, isLeft: false),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: _buildCorner(isTop: false, isLeft: true),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: _buildCorner(isTop: false, isLeft: false),
              ),

              // Animated Laser Sweep Line
              AnimatedBuilder(
                animation: _laserController,
                builder: (context, child) {
                  return Positioned(
                    top: 10 + (240 * _laserController.value),
                    left: 10,
                    right: 10,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppColors.cyberCyan,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cyberCyan.withValues(alpha: 0.8),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Subtitle instruction
              Positioned(
                bottom: -32,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      context.tr('point_camera_at_barcode'),
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCorner({required bool isTop, required bool isLeft}) {
    const double size = 26.0;
    const double thickness = 3.5;
    const color = AppColors.cyberCyan;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: color, width: thickness)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: color, width: thickness)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: color, width: thickness)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: color, width: thickness)
              : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildBottomLookupPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('manual_code_lookup_title'),
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_isProcessingCode) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // Quick Text Input Row
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _manualInputController,
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: context.tr('manual_code_hint'),
                        hintStyle: TextStyle(
                          color: context.textMutedColor,
                          fontSize: 12,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        filled: true,
                        fillColor: context.isDarkMode
                            ? AppColors.darkNavy
                            : AppColors.lightBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: context.borderColor),
                        ),
                      ),
                      onSubmitted: _handleCodeDetected,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _handleCodeDetected(_manualInputController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.electricBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.search_rounded, size: 18),
                    label: Text(context.tr('search_code_btn'),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Quick Preset Machine Chips
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildQuickCodeChip('EXT-01', context.tr('chip_ext01')),
                  _buildQuickCodeChip('DR01', context.tr('chip_dr01')),
                  _buildQuickCodeChip('RS01', context.tr('chip_rs01')),
                  _buildQuickCodeChip('EXT-02', context.tr('chip_ext02')),
                  _buildQuickCodeChip('ARM-01', context.tr('chip_arm01')),
                  _buildQuickCodeChip('TB01', context.tr('chip_tb01')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCodeChip(String code, String name) {
    final label = '$code ($name)';
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ActionChip(
        label: Text(label),
        backgroundColor: context.isDarkMode
            ? AppColors.darkNavy
            : const Color(0xFFE2E8F0),
        side: BorderSide(color: context.borderColor),
        labelStyle: TextStyle(
          color: context.textPrimaryColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        onPressed: () => _handleCodeDetected(code),
      ),
    );
  }
}
