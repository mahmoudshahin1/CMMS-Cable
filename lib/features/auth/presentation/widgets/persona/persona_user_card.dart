import 'package:flutter/material.dart';
import '../../../domain/models/user_model.dart';
import '../../../domain/enums/user_role.dart';
import '../../../../../core/theme/app_colors.dart';

class PersonaUserCard extends StatelessWidget {
  final UserModel user;
  final bool isSelected;
  final VoidCallback onTap;

  const PersonaUserCard({
    super.key,
    required this.user,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final role = user.role;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? role.roleColor.withValues(alpha: 0.12)
            : (context.isDarkMode
                ? AppColors.slateCard
                : AppColors.energyaLightSurface),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? role.roleColor : context.borderColor,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 4,
        ),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: role.roleColor.withValues(alpha: 0.2),
          child: Icon(role.icon, color: role.roleColor, size: 20),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                user.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected
                      ? (context.isDarkMode ? Colors.white : role.roleColor)
                      : context.textPrimaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: role.roleColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                role.badgeTitle,
                style: TextStyle(
                  color: role.roleColor,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            '${user.email} • ${user.department != null ? user.department!.name.toUpperCase() : (user.speciality ?? 'Plant-wide')}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.textMutedColor,
              fontSize: 11.5,
            ),
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle_rounded, color: role.roleColor, size: 22)
            : Icon(Icons.circle_outlined,
                color: context.textMutedColor, size: 20),
        onTap: onTap,
      ),
    );
  }
}
