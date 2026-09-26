import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../../domain/enums/user_role.dart';
// switch_persona_bottom_sheet removed — persona switching is disabled
import '../../../../core/theme/app_colors.dart';

class PersonaIndicatorChip extends StatelessWidget {
  final bool compact;

  const PersonaIndicatorChip({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is! Authenticated) {
          return const SizedBox.shrink();
        }

        final user = state.user;
        final role = user.role;
        final roleColor = role.roleColor;

        // Display-only chip — no tap action (persona switching disabled)
        return Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 6 : 8,
              vertical: compact ? 3 : 5,
            ),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: roleColor.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: compact ? 10 : 12,
                  backgroundColor: roleColor.withValues(alpha: 0.25),
                  child: Icon(
                    role.icon,
                    color: roleColor,
                    size: compact ? 12 : 14,
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: compact ? 75 : 110),
                          child: Text(
                            user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.textPrimaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        role.badgeTitle,
                        style: TextStyle(
                          color: roleColor,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                   ],
                ),
              ],
            ),
          );
      },
    );
  }
}
