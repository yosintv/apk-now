# YoSinTV Remote Configuration Guide

Complete guide to managing app features via remote JSON configuration files.

## 📍 Configuration Files

Two JSON configuration files control the entire app:

### **1. Main Config** (Primary)
- **File**: `config/main-config.json`
- **URL**: `https://api.singhs.com.np/api/main-config.json`
- **Purpose**: Primary app configuration source

### **2. Alt Config** (Fallback)
- **File**: `config/alt-config.json`
- **URL**: `https://api.singhs.com.np/api/alt-config.json`
- **Purpose**: Used if main config fails to load

## 🔄 Config Loading Strategy

```
App Starts
    ↓
Try: GET main-config.json
    ↓
Success? → Use main config → Done ✅
    ↓
Fail? → Try: GET alt-config.json
    ↓
Success? → Use alt config → Done ✅
    ↓
Fail? → Use local defaults (lib/config/defaults.dart)
```

## 📋 Configuration Parameters

### **App Control Flags**

```json
{
  "reviewMode": false,
  "streamingEnabled": true,
  "adsEnabled": true,
  "bannerEnabled": true,
  "rewardedEnabled": true,
  "appOpenEnabled": true,
  "interstitialEnabled": true
}
```

| Parameter | Type | Purpose | Values |
|-----------|------|---------|--------|
| `reviewMode` | boolean | Disable ads for store review | true/false |
| `streamingEnabled` | boolean | Show streaming links | true/false |
| `adsEnabled` | boolean | Master ad switch | true/false |
| `bannerEnabled` | boolean | Banner ads in lists | true/false |
| `rewardedEnabled` | boolean | Rewarded ads | true/false |
| `appOpenEnabled` | boolean | Ad on app resume | true/false |
| `interstitialEnabled` | boolean | Full-screen ad on match detail | true/false |

### **AdMob Ad Unit IDs**

```json
{
  "bannerAdId": "ca-app-pub-5525538810839147/3825132304",
  "rewardedAdId": "ca-app-pub-5525538810839147/6942250234",
  "appOpenAdId": "ca-app-pub-5525538810839147/1223019695",
  "interstitialAdId": "ca-app-pub-5525538810839147/4446428920"
}
```

### **Maintenance & Messages**

```json
{
  "maintenanceMode": false,
  "maintenanceMessage": "App is under maintenance. Please try again later.",
  "appMessage": "Welcome to YoSinTV!",
  "appMessageType": "info"
}
```

| Parameter | Type | Purpose | Notes |
|-----------|------|---------|-------|
| `maintenanceMode` | boolean | Block all navigation | true → Show maintenance screen |
| `maintenanceMessage` | string | Message to display | Max 200 characters |
| `appMessage` | string | Announcement banner | Empty string = no banner |
| `appMessageType` | string | Banner color | "info" / "warning" / "error" |

### **Social Links**

```json
{
  "whatsappLink": "https://wa.me/1234567890",
  "telegramLink": "https://t.me/yosintv"
}
```

### **API Endpoints**

```json
{
  "footballApiUrl": "https://api.singhs.com.np/api/football-matches.json",
  "cricketApiUrl": "https://api.singhs.com.np/api/cricket-matches.json",
  "articlesApiUrl": "https://api.singhs.com.np/api/articles.json",
  "altConfigUrl": "https://api.singhs.com.np/api/alt-config.json"
}
```

## 🎯 Common Use Cases

### **Scenario 1: Disable Ads During App Review**

**Current config:**
```json
{
  "adsEnabled": true,
  "reviewMode": false
}
```

**For App Store/Play Store Review:**
```json
{
  "reviewMode": true,
  "adsEnabled": false
}
```

**Result:** ✅ Ads disabled, app can pass review
**Then restore after approval** ✅

---

### **Scenario 2: Maintenance Mode**

**Normal state:**
```json
{
  "maintenanceMode": false
}
```

**During server maintenance:**
```json
{
  "maintenanceMode": true,
  "maintenanceMessage": "We're updating our servers. Back in 2 hours!"
}
```

**Result:** 🔧 Users see maintenance screen, no navigation possible
**Automatically restores when you disable it** ✅

---

### **Scenario 3: Important Announcement**

**Add banner message:**
```json
{
  "appMessage": "🔴 Live: Cricket World Cup Final - India vs Australia!",
  "appMessageType": "warning"
}
```

**Result:** ⚠️ Yellow banner shows on home screen

**Remove after event:**
```json
{
  "appMessage": ""
}
```

---

### **Scenario 4: Change Ad IDs**

**Current ads:**
```json
{
  "bannerAdId": "ca-app-pub-OLD_ID"
}
```

**New ad account:**
```json
{
  "bannerAdId": "ca-app-pub-NEW_ID"
}
```

**Result:** 🎯 New ads serve immediately without app update ✅

---

## 🚀 Hosting Your Config Files

### **Option 1: Your Own Server** (Recommended for production)

```
1. Host files on your server
   server.com/api/main-config.json
   server.com/api/alt-config.json

2. Update URLs in app:
   lib/config/remote_config.dart
   
3. Change config anytime → App gets new config on next start
```

### **Option 2: Firebase Hosting** (Fast & Free)

```
1. Create Firebase project: https://firebase.google.com
2. Create files in Firebase Hosting
3. Deploy:
   firebase deploy
4. URLs become:
   https://your-project.web.app/api/main-config.json
5. Update app URLs
```

### **Option 3: GitHub** (Easy for testing)

```
1. Create config files in GitHub repo
2. Use Raw URLs:
   https://raw.githubusercontent.com/your-user/your-repo/main/config/main-config.json
3. Update app URLs
```

### **Option 4: JSONBin.io** (Easy, no setup)

```
1. Go to https://jsonbin.io
2. Create new bin with JSON content
3. Get URL from "Share" button
4. Update app URLs
```

---

## 📝 JSON Structure (Complete Example)

```json
{
  "reviewMode": false,
  "streamingEnabled": true,
  "adsEnabled": true,
  "bannerEnabled": true,
  "rewardedEnabled": true,
  "appOpenEnabled": true,
  "interstitialEnabled": true,
  
  "bannerAdId": "ca-app-pub-5525538810839147/3825132304",
  "rewardedAdId": "ca-app-pub-5525538810839147/6942250234",
  "appOpenAdId": "ca-app-pub-5525538810839147/1223019695",
  "interstitialAdId": "ca-app-pub-5525538810839147/4446428920",
  
  "maintenanceMode": false,
  "maintenanceMessage": "App is under maintenance. Please try again later.",
  "appMessage": "Welcome to YoSinTV v1.1.0!",
  "appMessageType": "info",
  
  "whatsappLink": "https://wa.me/1234567890",
  "telegramLink": "https://t.me/yosintv",
  
  "popupEnabled": false,
  "popupTitle": "Welcome to YoSinTV",
  "popupText": "Your daily sports companion!",
  
  "matchLinks": [],
  "articles": [],
  
  "footballApiUrl": "https://api.singhs.com.np/api/football-matches.json",
  "cricketApiUrl": "https://api.singhs.com.np/api/cricket-matches.json",
  "articlesApiUrl": "https://api.singhs.com.np/api/articles.json",
  "altConfigUrl": "https://api.singhs.com.np/api/alt-config.json"
}
```

---

## 🧪 Testing Config Changes Locally

### **Method 1: Modify Local Defaults**
Edit `lib/config/defaults.dart` and rebuild:
```bash
flutter run
```

### **Method 2: Host Locally (Python)**
```bash
cd config/
python -m http.server 8000
```

Then update URLs in app to `http://localhost:8000/main-config.json`

### **Method 3: Use Online JSON Hosting**
1. Copy JSON to https://jsonbin.io
2. Get shareable URL
3. Update app URLs temporarily
4. Test changes

---

## 🎛️ Control Matrix

| Feature | Config Key | On | Off |
|---------|-----------|----|----|
| **Ads (All)** | adsEnabled | Ads show | No ads |
| **Banner Ads** | bannerEnabled | Every 3 items | No banners |
| **Interstitial** | interstitialEnabled | Match detail | Skip fullscreen ad |
| **App Open** | appOpenEnabled | On resume | Skip resume ad |
| **Streaming** | streamingEnabled | Show links | Hide links |
| **Review Mode** | reviewMode | No ads | Ads enabled |
| **Maintenance** | maintenanceMode | Block app | Normal |

---

## 📊 Config Update Flow

```
1. Edit config/main-config.json
2. Upload to https://api.singhs.com.np/api/main-config.json
3. Users restart app (or wait for app launch)
4. App fetches new config
5. Features update immediately
6. No Play Store update needed!
```

---

## ✅ Deployment Checklist

Before releasing to production:

- [ ] Test all features are disabled correctly
- [ ] Test maintenance mode (block all navigation)
- [ ] Test app messages (show/hide)
- [ ] Test ad IDs are correct
- [ ] Test API endpoints are reachable
- [ ] Have alt-config.json as fallback
- [ ] Document all config parameters
- [ ] Set up alerting if config fetch fails
- [ ] Plan maintenance windows
- [ ] Test network timeout scenarios

---

## 🔗 Current URLs

**Main Config:**
```
https://api.singhs.com.np/api/main-config.json
```

**Alt Config:**
```
https://api.singhs.com.np/api/alt-config.json
```

**To change:** Update `lib/config/remote_config.dart`

---

## 🚨 Error Handling

**If main-config fails:**
```
App tries alt-config.json → If alt fails → Use local defaults
```

**This ensures app always works**, even if both remote configs are down!

---

## 📱 Real-World Example

### Morning Deployment:
```json
{
  "appMessage": "🔴 LIVE NOW: India vs Pakistan Cricket!",
  "appMessageType": "warning"
}
```

### Evening:
```json
{
  "appMessage": "📊 Match Highlights: India wins by 50 runs!",
  "appMessageType": "info"
}
```

### Before App Review:
```json
{
  "reviewMode": true,
  "adsEnabled": false
}
```

### After Approval:
```json
{
  "reviewMode": false,
  "adsEnabled": true
}
```

---

## 💡 Best Practices

1. **Always have alt-config.json** as fallback
2. **Version your configs** (add comment with timestamp)
3. **Test locally first** before deploying to production
4. **Monitor config fetch** errors in logs
5. **Use maintenance mode** for planned downtime
6. **Update ads without rebuilding** app
7. **A/B test features** by enabling for percent of users
8. **Keep messages brief** (max 200 characters)

---

## 🎯 Next: Update App URLs

If hosting configs on different server, update:
```dart
// lib/config/remote_config.dart
final String primaryUrl = 'YOUR_CONFIG_URL/main-config.json';
final String fallbackUrl = 'YOUR_CONFIG_URL/alt-config.json';
```

Then rebuild app:
```bash
flutter run
```

---

**Your app is now fully controlled via these two JSON files!** 🎉

Make changes anytime → Users get updates on next app launch → No Store update needed!
