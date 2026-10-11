# Church Service Management System

Flutter Web offline-first church service management system.

## Run the web app

Install the Flutter dependencies, then start Chrome with the Supabase project URL and publishable/anon key:

```powershell
flutter pub get
flutter run -d chrome `
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_PUBLISHABLE_KEY
```

Sign in with an active Supabase Auth account that has an active row in `system_administrators` (matching `auth_user_id`). The session opens the system admin dashboard. From there, select a service or create one; open **Settings → Service → Stages and classes** to set up the hierarchy, then explore the dashboard, students, attendance, follow-up, servants, reports, graduation export, and sync center.

The app needs a configured Supabase project and the corresponding database schema/policies. Without these, sign-in and service setup will not work. Student, attendance, and follow-up changes are queued locally and can be reviewed in the sync center.
