# Golden test workflow

Golden tests and committed PNG baselines live under `test/goldens/`.

## Run the full suite

From the repository root:

```bash
flutter pub get
flutter test --update-goldens
flutter test
```

The first command refreshes every golden referenced by the tests. Review the changed PNGs before committing them. The second command verifies the committed baselines without updating them.

To run only the golden-tagged tests:

```bash
flutter test --tags golden
flutter test --update-goldens --tags golden
```

## Determinism requirements

- Keep test locale fixed to Arabic (`ar`) and direction RTL.
- Use the shared `golden_test_helper.dart` setup for fonts, date localization, fixed viewport, device pixel ratio 1.0 and text scaling.
- Use fixed fixture records and fixed dates/times; do not read live Supabase data, system clock values or device camera frames.
- Override providers/repositories at the widget boundary. Golden tests must not require a live Supabase project, account, network connection or physical camera.
- QR camera preview should be represented by a deterministic test-only placeholder, with that substitution documented in the relevant test.
- Keep PNGs in `test/goldens/images/` (and existing task-specific subdirectories) and ensure Git tracks them.

## Naming

Use `<screen>_<viewport>_<theme>.png` for standard variants. Keep the existing `_scale13` suffix for 1.3x text-scale variants. Add explicit state and role tokens when multiple captures of the same screen are required (for example, `reports_filter_open_mobile_light.png` or `service_dashboard_stage_leader_desktop_dark.png`).

The authoritative route/page inventory and coverage audit is in [MANIFEST.md](MANIFEST.md).
