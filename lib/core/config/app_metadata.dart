class AppMetadata {
  const AppMetadata._();

  static const String appName = 'أسرة تلاميذ المسيح';
  static const String appFullName = 'نظام إدارة خدمة أسرة تلاميذ المسيح';
  static const String shortName = 'إدارة الخدمة';

  /// Semantic version of the application.
  static const String version = '0.2.0';

  /// Monotonically increasing build number for deployment & cache busting.
  static const String buildNumber = '2';

  /// Full version display representation (e.g. "0.2.0+2").
  static const String versionDisplay = '$version+$buildNumber';

  /// Release date for the current deployment.
  static const String releaseDate = '2026-11-08';

  /// Firebase Hosting primary production domain.
  static const String hostingUrl = 'https://church-services-management.web.app';

  /// Firebase Project ID.
  static const String firebaseProjectId = 'church-services-management';

  static const String copyright =
      '© أسرة تلاميذ المسيح - كنيسة السيدة العذراء مريم عياد بك';

  static const String description =
      'نظام متكامل لإدارة خدمات الكنيسة ومتابعة الحضور والنوتة الروحية مع دعم العمل دون اتصال بالإنترنت (Offline-First) وتطبيق الويب التقدمي (PWA).';
}
