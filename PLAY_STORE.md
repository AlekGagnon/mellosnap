# Play Store release (MelloSnap)

## Already configured in the project

- `applicationId` / namespace: `com.mellosnap.app`
- Release signing via `android/key.properties` + `android/app/upload-keystore.jks`
- Both files are **gitignored** — back them up offline

## Release SHA-1 (Google Sign-In / Firebase)

```
CE:5F:D1:60:BA:8E:11:19:5F:A7:0F:87:7B:8B:69:28:60:A4:F2:A9
```

Add this SHA-1 to your **Android** OAuth client in Google Cloud (package `com.mellosnap.app`), in addition to the debug SHA-1.

## Build the upload file (AAB)

```powershell
cd mellosnap
flutter build appbundle --release
```

Output:

```
build/app/outputs/bundle/release/app-release.aab
```

## Play Console steps

1. [play.google.com/console](https://play.google.com/console) → Create app
2. Enable **Play App Signing** when asked
3. Upload `app-release.aab` to **Internal testing** first
4. Fill store listing, Data safety, privacy policy
5. Promote to Production when ready

## Version bumps

In `pubspec.yaml`:

```yaml
version: 1.0.0+1   # name+code → versionName+versionCode
```

Each Play upload needs a **higher** `+N` (versionCode).

## Secrets checklist before upload

- [ ] Backup `upload-keystore.jks` + `key.properties` passwords somewhere safe
- [ ] `.env` has production Supabase / Stripe publishable / OneSignal IDs as needed
- [ ] Stripe **live** keys + live webhook (see STRIPE_SETUP.md)
- [ ] Google OAuth Android client includes **release** SHA-1 above
- [ ] Firebase `google-services.json` is for `com.mellosnap.app`
