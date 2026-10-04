/// What an account may do. The database enforces the same rules, so the app
/// only shows what is allowed anyway.
enum Role { user, operator, admin }

/// A user's request to become an operator.
enum OperatorRequest { pending, rejected }

/// The signed-in person's row in the profiles table.
class Profile {
  const Profile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.operatorRequest,
    this.suspendedReason,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    final request = json['operator_request'] as String?;
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      role: Role.values.byName(json['role'] as String),
      operatorRequest: request == null
          ? null
          : OperatorRequest.values.byName(request),
      suspendedReason: json['suspended_reason'] as String?,
    );
  }

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final Role role;
  final OperatorRequest? operatorRequest;

  /// Why an admin suspended the account; null while it is active.
  final String? suspendedReason;

  bool get isSuspended => suspendedReason != null;

  String get fullName => '$firstName $lastName'.trim();
}
