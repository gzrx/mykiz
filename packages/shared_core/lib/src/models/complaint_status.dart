/// Linear complaint status progression: submitted → in_progress → resolved.
enum ComplaintStatus {
  submitted,
  inProgress,
  resolved;

  /// Returns the next valid status, or null if already resolved.
  ComplaintStatus? get next => switch (this) {
        ComplaintStatus.submitted => ComplaintStatus.inProgress,
        ComplaintStatus.inProgress => ComplaintStatus.resolved,
        ComplaintStatus.resolved => null,
      };

  /// Validates whether transitioning to [target] is allowed.
  bool canTransitionTo(ComplaintStatus target) => next == target;
}
