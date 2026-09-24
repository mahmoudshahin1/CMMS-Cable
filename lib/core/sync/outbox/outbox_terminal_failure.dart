import 'command_error_classifier.dart';
import 'outbox_command.dart';

/// Encapsulates a terminal failure dispatched from the outbox.
class OutboxTerminalFailure {
  final OutboxCommand command;
  final CommandClassification classification;
  final String rawError;

  const OutboxTerminalFailure({
    required this.command,
    required this.classification,
    required this.rawError,
  });

  String get userMessage => classification.localizedMessage;
}
