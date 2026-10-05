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
