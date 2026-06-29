# Stripe setup (MelloSnap)

## 1. Stripe Dashboard

1. Create an account at [stripe.com](https://stripe.com).
2. Enable **test mode** (toggle top-right).
3. Copy keys from **Developers → API keys**:
   - **Publishable key** (`pk_test_...`) → app `.env`
   - **Secret key** (`sk_test_...`) → Supabase secrets only

## 2. App `.env`

```env
STRIPE_PUBLISHABLE_KEY=pk_test_xxxxxxxx
```

Restart the app after changing `.env`.

## 3. Supabase secrets

```bash
cd mellosnap
supabase secrets set STRIPE_SECRET_KEY=sk_test_xxxxxxxx
```

After creating the webhook (step 5):

```bash
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_xxxxxxxx
```

## 4. Database migration

Apply the Stripe columns on `orders`:

```bash
supabase db push
```

Or run `supabase/migrations/20250626120000_stripe_orders.sql` in the SQL editor.

## 5. Deploy Edge Functions

```bash
supabase functions deploy create-payment-intent
supabase functions deploy stripe-webhook --no-verify-jwt
```

`stripe-webhook` must be deployed **without JWT verification** (Stripe calls it directly).

Webhook URL format:

```
https://<PROJECT_REF>.supabase.co/functions/v1/stripe-webhook
```

In Stripe → **Developers → Webhooks → Add endpoint**:

- Event: `payment_intent.succeeded`
- URL: your `stripe-webhook` function URL
- Copy the **Signing secret** (`whsec_...`) into Supabase secrets

## 6. Test cards

| Card            | Result        |
|-----------------|---------------|
| 4242 4242 4242 4242 | Success   |
| Any future date |               |
| Any CVC         |               |

Tap **Confirm & pay** on checkout — Stripe's native Payment Sheet slides up (card form; Google Pay when available). No custom card UI in the app.

## 7. Google Pay (Android)

1. **Stripe Dashboard → Settings → Payment methods** — enable **Google Pay** (test mode).
2. Android manifest already includes `com.google.android.gms.wallet.api.enabled` (see `android/app/src/main/AndroidManifest.xml`).
3. `PaymentService` passes `PaymentSheetGooglePay` with `merchantCountryCode: CA`, `currencyCode: CAD`, and `testEnv: true` in debug builds.
4. **Testing**: Google Pay usually requires a **physical Android device** with a test card in Google Wallet. The emulator can still test **card entry** with `4242 4242 4242 4242`.
5. Before production: set `testEnv: false` (release builds use `kDebugMode == false` automatically).

## 8. Mobile builds

- **Android**: `MainActivity` uses `FlutterFragmentActivity` (required by Stripe).
- **iOS**: run `cd ios && pod install` after `flutter pub get`.

## 9. Go live

Replace `pk_test_` / `sk_test_` with live keys, redeploy functions, and create a live-mode webhook endpoint.
