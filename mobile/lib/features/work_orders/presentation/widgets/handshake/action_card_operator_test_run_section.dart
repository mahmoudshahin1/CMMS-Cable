import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

/// Action card section for Line Operator or Production Supervisor to execute
/// the test run check phase with 3 outcomes: Fixed, Needs Follow-up, or Not Fixed.
class ActionCardOperatorTestRunSection extends StatefulWidget {
  final bool isProcessing;
  final void Function(String outcome, String? comments) onConfirmTestRun;

  const ActionCardOperatorTestRunSection({
    super.key,
    required this.isProcessing,
    required this.onConfirmTestRun,
  });

  @override
  State<ActionCardOperatorTestRunSection> createState() =>
      _ActionCardOperatorTestRunSectionState();
}

class _ActionCardOperatorTestRunSectionState
    extends State<ActionCardOperatorTestRunSection> {
  String _selectedOutcome = 'fixed'; // 'fixed' | 'needs_followup' | 'not_fixed'
  final _notesController = TextEditingController();
  String? _validationError;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final notes = _notesController.text.trim();
    if (_selectedOutcome != 'fixed' && notes.isEmpty) {
      setState(() {
        _validationError = 'Rejection notes are required for this outcome.';
      });
      return;
    }
    setState(() => _validationError = null);
    widget.onConfirmTestRun(
      _selectedOutcome,
      notes.isNotEmpty ? notes : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Action Required: Perform field line test run with raw material and confirm machine outcome.',
          style: TextStyle(color: context.textPrimaryColor, fontSize: 12.5),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildOutcomeOption(
              label: 'Fixed',
              outcomeKey: 'fixed',
              color: AppColors.runningEmerald,
              icon: Icons.check_circle_outline_rounded,
            ),
            const SizedBox(width: 8),
            _buildOutcomeOption(
              label: 'Follow-up',
              outcomeKey: 'needs_followup',
              color: AppColors.idleAmber,
              icon: Icons.sync_problem_rounded,
            ),
            const SizedBox(width: 8),
            _buildOutcomeOption(
              label: 'Not Fixed',
              outcomeKey: 'not_fixed',
              color: AppColors.downMaintenanceRed,
              icon: Icons.cancel_outlined,
            ),
          ],
        ),
        if (_selectedOutcome != 'fixed') ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            maxLines: 2,
            enabled: !widget.isProcessing,
            decoration: InputDecoration(
              labelText: 'Production Feedback / Rejection Notes *',
              labelStyle: TextStyle(
                color: _validationError != null
                    ? AppColors.downMaintenanceRed
                    : context.textSecondaryColor,
                fontSize: 12,
              ),
              hintText: _selectedOutcome == 'needs_followup'
                  ? 'Describe what still requires attention...'
                  : 'State why the repair failed...',
              hintStyle: TextStyle(
                color: context.textSecondaryColor.withValues(alpha: 0.7),
                fontSize: 11.5,
              ),
              errorText: _validationError,
              filled: true,
              fillColor: isDark
                  ? AppColors.slateCard
                  : AppColors.lightBorder.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _selectedOutcome == 'not_fixed'
                      ? AppColors.downMaintenanceRed
                      : AppColors.idleAmber,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: widget.isProcessing ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _buttonColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: widget.isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(_buttonIcon, size: 18),
          label: Text(
            widget.isProcessing ? 'Submitting...' : _buttonLabel,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Color get _buttonColor {
    switch (_selectedOutcome) {
      case 'needs_followup':
        return AppColors.idleAmber;
      case 'not_fixed':
        return AppColors.downMaintenanceRed;
      case 'fixed':
      default:
        return AppColors.runningEmerald;
    }
  }

  IconData get _buttonIcon {
    switch (_selectedOutcome) {
      case 'needs_followup':
        return Icons.reply_rounded;
      case 'not_fixed':
        return Icons.close_rounded;
      case 'fixed':
      default:
        return Icons.fact_check_rounded;
    }
  }

  String get _buttonLabel {
    switch (_selectedOutcome) {
      case 'needs_followup':
        return 'Bounce Back: Needs Follow-up';
      case 'not_fixed':
        return 'Reject Test Run: Not Fixed';
      case 'fixed':
      default:
        return 'Step 4: Confirm Test Run & Line Ready';
    }
  }

  Widget _buildOutcomeOption({
    required String label,
    required String outcomeKey,
    required Color color,
    required IconData icon,
  }) {
    final isSelected = _selectedOutcome == outcomeKey;
    return Expanded(
      child: InkWell(
        onTap: widget.isProcessing
            ? null
            : () {
                setState(() {
                  _selectedOutcome = outcomeKey;
                  _validationError = null;
                });
              },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : context.borderColor,
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSelected ? color : context.textSecondaryColor),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : context.textPrimaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
