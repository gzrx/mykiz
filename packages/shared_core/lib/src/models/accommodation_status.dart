/// Accommodation application status state machine.
///
/// Valid transitions:
/// - submitted → approved, rejected
/// - approved → checkedIn
/// - checkedIn → checkedOut
/// - checkedOut → (terminal)
/// - rejected → (terminal)
enum AccommodationStatus {
  submitted,
  approved,
  checkedIn,
  checkedOut,
  rejected;

  /// Valid transitions from this status.
  List<AccommodationStatus> get validTransitions => switch (this) {
        AccommodationStatus.submitted => [
          AccommodationStatus.approved,
          AccommodationStatus.rejected,
        ],
        AccommodationStatus.approved => [AccommodationStatus.checkedIn],
        AccommodationStatus.checkedIn => [AccommodationStatus.checkedOut],
        AccommodationStatus.checkedOut => [],
        AccommodationStatus.rejected => [],
      };

  /// Validates whether transitioning to [target] is allowed.
  bool canTransitionTo(AccommodationStatus target) =>
      validTransitions.contains(target);

  /// Whether this status counts as "active" (blocks new submissions of same type).
  bool get isActive =>
      this == submitted || this == approved || this == checkedIn;

  /// Whether this is a terminal state (allows new submissions).
  bool get isTerminal => this == checkedOut || this == rejected;
}
