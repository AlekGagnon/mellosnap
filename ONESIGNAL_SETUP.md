# OneSignal setup (MelloSnap)

App code is ready (`NotificationService`). You still need the OneSignal + FCM console steps below for pushes to arrive on a device.

## 1. OneSignal app

1. Create an app at [onesignal.com](https://onesignal.com).
2. Choose **Google Android (FCM)** (and iOS later if needed).
3. Copy **OneSignal App ID** → `.env`:

```env
ONESIGNAL_APP_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

## 2. Android FCM

1. Firebase Console → add Android app with package `com.mellosnap.app`.
2. Download `google-services.json` → place in `android/app/`.
3. In OneSignal → Platforms → Google Android → upload your **FCM v1** service account JSON (from Firebase).

OneSignal’s Flutter SDK docs also cover adding the Google Services Gradle plugin if required by your Firebase setup.

## 3. Permission

Android 13+ needs runtime notification permission — the app calls `OneSignal.Notifications.requestPermission` (Settings toggle + first login).

`AndroidManifest` includes `POST_NOTIFICATIONS`.

## 4. Tags (already written by the app)

| Tag | Values | Use in OneSignal |
|-----|--------|------------------|
| `roll_status` | `none`, `in_progress`, `complete`, `format`, `checkout` | Unfinished / unpaid roll Journeys |
| `photos_taken` | `0`–`24` | Optional copy personalization |
| `order_status` | `none`, `pending`, `paid` | Payment reminder Journey |

External ID = Supabase `auth.users.id` (`OneSignal.login(userId)`).

## 5. Suggested Journeys / segments

1. **Finish roll** — `roll_status = in_progress` AND last session > 24h  
   Message: “You’re mid-roll — finish your 24 shots.”

2. **Send to print** — `roll_status` is `complete` OR `format` OR `checkout`  
   Message: “Your roll is ready — choose a format and order prints.”

3. **Pay order** — `order_status = pending`  
   Message: “Your MelloSnap order is waiting for payment.”

Create these in OneSignal → **Journeys** or **Messages → New Push** with audience filters on tags.

## 6. Test

1. Set `ONESIGNAL_APP_ID` and restart the app.
2. Sign in → allow notifications.
3. OneSignal → Audience → check the user (External ID = your Supabase UUID).
4. Send a test push to that user.
