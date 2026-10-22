import 'servant_profile.dart';
import 'system_admin_profile.dart';

sealed class SessionIdentity {
  const SessionIdentity();
}

class SuperAdminIdentity extends SessionIdentity {
  const SuperAdminIdentity(this.profile);
  final SystemAdminProfile profile;
}

class ServantIdentity extends SessionIdentity {
  const ServantIdentity(this.profile);
  final ServantProfile profile;
}

class MultiServiceServantIdentity extends SessionIdentity {
  const MultiServiceServantIdentity(this.profiles);
  final List<ServantProfile> profiles;
}

class PendingServantIdentity extends SessionIdentity {
  const PendingServantIdentity({
    required this.name,
    required this.status,
    this.phone,
    this.birthDate,
    this.workStudy,
  });
  final String name;
  final String status;
  final String? phone;
  final DateTime? birthDate;
  final String? workStudy;
}
