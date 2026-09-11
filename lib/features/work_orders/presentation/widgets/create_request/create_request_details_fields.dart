import 'package:flutter/material.dart';

import '../../../../../core/localization/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';

/// Form fields for Work Order fault title and detailed notes.
class CreateRequestDetailsFields extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;

  const CreateRequestDetailsFields({
    super.key,
    required this.titleController,
    required this.descriptionController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.edit_note_rounded,
              size: 16,
              color: context.isDarkMode
                  ? AppColors.cyberCyan
                  : context.brandPrimary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                context.tr('fault_title_notes_step'),
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: titleController,
          decoration: InputDecoration(
            labelText: context.tr('fault_title_field'),
            hintText: context.tr('fault_title_hint'),
            filled: true,
            fillColor: context.cardBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return context.tr('fault_title_error');
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: context.tr('additional_notes_field'),
            hintText: context.tr('additional_notes_hint'),
            filled: true,
            fillColor: context.cardBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
