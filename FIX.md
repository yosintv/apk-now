# YoSinTV — Things to Fix Before Publishing

---

## ❌ Critical Blockers (must fix before Play Store)

### 1. `key.properties` is missing
`android/key.properties` does not exist. `build.gradle.kts` reads it for release signing — without it the release APK/AAB is unsigned and Play Store will reject it.

Create `android/key.properties`:
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=YOUR_KEY_ALIAS
storeFile=../your-keystore.jks
```

---

### 2. Build AAB for Play Store (not APK)
Play Store requires Android App Bundle format:
```bash
flutter build appbundle --release
```
Upload `build/app/outputs/bundle/release/app-release.aab` to Play Console.

---

## ⚠️ Should Fix (won't block but are wrong)

> **Items 1–4 below do NOT need a rebuild.**
> Every key in `assets/app_config.json` can be overridden dynamically from
> `https://cdn.singhs.com.np/api/main-config.json` — update the JSON there and
> users get the fix on next app launch, no store update needed.
>
> **Items 5–6 live in `.env` and DO require a rebuild.**

---

### 1. Wrong app ID in update URL (`assets/app_config.json` or remote config)
Current:
```json
"update_url": "https://play.google.com/store/apps/details?id=net.yosintv.app"
```
Fix — actual app ID is `net.yosintv.tv`:
```json
"update_url": "https://play.google.com/store/apps/details?id=net.yosintv.tv"
```

---

### 2. Outdated app message (`assets/app_config.json` or remote config)
Current:
```json
"app_message": "Welcome to YoSinTV v1.1.0! Enjoy live cricket & football updates."
```
Fix — update version or clear it:
```json
"app_message": "Welcome to YoSinTV v1.2.0! Enjoy live cricket & football updates."
```

---

### 3. Placeholder WhatsApp link (`assets/app_config.json` or remote config)
Current:
```json
"whatsapp_link": "https://wa.me/1234567890"
```
Fix — replace with your real WhatsApp number:
```json
"whatsapp_link": "https://wa.me/YOUR_REAL_NUMBER"
```

---

### 4. Placeholder Google Analytics ID (`assets/app_config.json` or remote config)
Current:
```json
"google_analytics_id": "G-XXXXXXXXXX"
```
Fix — analytics won't fire until this is a real ID:
```json
"google_analytics_id": "G-YOUR_REAL_ID"
```

---

### 5. Placeholder Firebase keys (`.env` — requires rebuild)
Current:
```
FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID
FIREBASE_ANDROID_API_KEY=YOUR_ANDROID_API_KEY
```
Fix — replace with real values from Firebase Console → Project Settings → Your Apps (Android).
Push notifications will not work until these are set.

---

### 6. Test Device ID still active (`.env` — requires rebuild)
Current:
```
ADMOB_TEST_DEVICE_ID=B0C21075E0EC0718D5B34922752D7325
```
Fix — clear before publishing so real users don't get test ads:
```
ADMOB_TEST_DEVICE_ID=
```
