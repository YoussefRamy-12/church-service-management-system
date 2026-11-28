class ServantCandidate {
  const ServantCandidate({required this.authUserId, required this.fullName, required this.serviceNames, this.phoneSuffix});
  final String authUserId;
  final String fullName;
  final String? phoneSuffix;
  final List<String> serviceNames;
  factory ServantCandidate.fromMap(Map<String, dynamic> row) => ServantCandidate(
    authUserId: row['auth_user_id'] as String,
    fullName: row['full_name'] as String,
    phoneSuffix: row['phone_suffix'] as String?,
    serviceNames: (row['service_names'] as List<dynamic>? ?? const []).map((v) => v.toString()).toList(growable: false),
  );
}
