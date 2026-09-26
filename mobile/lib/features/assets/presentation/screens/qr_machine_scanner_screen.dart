import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/enums/department_type.dart';
import '../../domain/enums/machine_status.dart';
import '../../domain/models/machine_model.dart';
import '../cubit/machine_cubit.dart';
import '../cubit/machine_state.dart';
import '../widgets/scanned_machine_sheet.dart';
import '../widgets/scanner/scanner_manual_lookup_panel.dart';
import '../widgets/scanner/scanner_no_camera_fallback.dart';
import '../widgets/scanner/scanner_reticle_overlay.dart';

/// Screen allowing camera-based QR scanning and manual code lookup for cable factory machinery.
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
          content: Text(
            context.trArgs('machine_not_found_snack', {'code': trimmed}),
          ),
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
              icon: const Icon(
                Icons.flip_camera_ios_rounded,
                color: Colors.white70,
              ),
              tooltip: context.tr('camera_toggle_tooltip'),
              onPressed: () => _scannerController?.switchCamera(),
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
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
              errorBuilder: (context, error) =>
                  const ScannerNoCameraFallback(),
            )
          else
            const ScannerNoCameraFallback(),
          ScannerReticleOverlay(laserController: _laserController),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ScannerManualLookupPanel(
              manualInputController: _manualInputController,
              isProcessingCode: _isProcessingCode,
              onCodeSubmitted: _handleCodeDetected,
            ),
          ),
        ],
      ),
    );
  }
}
