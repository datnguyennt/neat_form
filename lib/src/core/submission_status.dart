/// Represents the lifecycle status of form submission.
enum NeatSubmissionStatus {
  /// Initial idle state before submission.
  idle,

  /// Submission is currently in progress (show loader).
  submitting,

  /// Submission succeeded.
  success,

  /// Submission failed with an error.
  failure;

  bool get isIdle => this == NeatSubmissionStatus.idle;
  bool get isSubmitting => this == NeatSubmissionStatus.submitting;
  bool get isSuccess => this == NeatSubmissionStatus.success;
  bool get isFailure => this == NeatSubmissionStatus.failure;
}
