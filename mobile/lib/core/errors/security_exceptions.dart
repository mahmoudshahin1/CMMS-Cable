class SecurityException implements Exception {
  final String message;
  const SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}

class UnauthorizedRoleException extends SecurityException {
  final String requiredRole;
  final String actualRole;

  const UnauthorizedRoleException({
    required this.requiredRole,
    required this.actualRole,
    String? message,
  }) : super(message ??
            'UNAUTHORIZED: Action requires [$requiredRole], but caller has [$actualRole].');
}

class UnassignedTechnicianException extends SecurityException {
  final String expectedTechId;
  final String actualTechId;

  const UnassignedTechnicianException({
    required this.expectedTechId,
    required this.actualTechId,
    String? message,
  }) : super(message ??
            'UNAUTHORIZED: Ticket is assigned to technician [$expectedTechId], caller is [$actualTechId].');
}

class IllegalStateTransitionException extends SecurityException {
  final String fromStatus;
  final String toStatus;

  const IllegalStateTransitionException({
    required this.fromStatus,
    required this.toStatus,
    String? message,
  }) : super(message ??
            'ILLEGAL_LIFECYCLE: Cannot transition work order from [$fromStatus] to [$toStatus].');
}
