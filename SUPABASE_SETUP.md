# Supabase setup for MelloSnap

## 1. Create project

1. Go to [supabase.com](https://supabase.com) and create a project.
2. Copy **Project URL** and **anon public key** (Settings → API).
3. Copy `.env.example` to `.env` and fill in the values.

## 2. Authentication providers

### Email

- Authentication → Providers → Email: **enabled**
- For development, disable **Confirm email** to test sign-up immediately.

### Google

1. [Google Cloud Console](https://console.cloud.google.com/) → APIs & Services → Credentials.
2. Create **OAuth client ID** (Web application) — use this as `GOOGLE_WEB_CLIENT_ID` in `.env`.
3. Create **OAuth client ID** (Android) with package `com.example.mellosnap` and your debug SHA-1:
   ```bash
   cd android && ./gradlew signingReport
   ```
4. Supabase → Authentication → Providers → Google: enable and paste Web client ID + secret.

### Apple (iOS)

1. Apple Developer → Identifiers → enable **Sign in with Apple** on your App ID.
2. Xcode → Runner → Signing & Capabilities → add **Sign in with Apple**.
3. Supabase → Authentication → Providers → Apple: enable with Service ID / key.

## 3. Redirect URLs

Authentication → URL Configuration:

- **Redirect URLs**: `io.supabase.mellosnap://login-callback/`
- **Site URL**: `http://localhost` (dev)

## 4. Troubleshooting re-login

If sign-in returns **Invalid login credentials** after sign out:

1. **Authentication → Users** — confirm your email exists, provider is `email`, and **Confirmed** is `true`.
2. **Authentication → Providers → Email** — for development, disable **Confirm email**.
3. If the account is unconfirmed, confirm it manually in the dashboard or use **Resend confirmation** in the app.
4. Use **Forgot my Password** in the app to reset the password via email.

## 5. Run the app

```bash
cp .env.example .env
# edit .env with your keys
flutter pub get
flutter run
```
