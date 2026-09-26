import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/enums/work_order_status.dart';

/// Helper to get badge colors for the 5-Step Handshake.
Color getHandshakeStatusColor(WorkOrderStatus status) {
  switch (status) {
    case WorkOrderStatus.open:
      return AppColors.downMaintenanceRed;
    case WorkOrderStatus.assigned:
    case WorkOrderStatus.pendingParts:
      return AppColors.idleAmber;
    case WorkOrderStatus.inProgress:
      return AppColors.electricBlue;
    case WorkOrderStatus.completed:
      return AppColors.cyberCyan;
    case WorkOrderStatus.verified:
      return AppColors.subduedViolet;
    case WorkOrderStatus.verifiedClosed:
      return AppColors.runningEmerald;
  }
}
