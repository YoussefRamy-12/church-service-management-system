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

## Auth email links

The app sends sign-up confirmation links to `/auth/callback` and password recovery links to `/reset-password` on the origin currently serving the app. For these links to work, add both paths to Supabase Auth **URL Configuration → Redirect URLs** for each environment (for local development, include the local origin; for production, include the deployed origin). The production **Site URL** should be set to the deployed app origin after deployment. The web host must serve the Flutter app for these paths (SPA fallback/rewrite to `index.html`).

Keep Supabase Auth email confirmation enabled if new servants must verify their email before they can sign in. The app-side flow cannot override a project setting that allows unconfirmed sign-ins. The reset email opens a one-time recovery session in the browser; the servant must enter and save a new password before signing in again.
