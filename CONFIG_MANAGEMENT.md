# YoSinTV Remote Configuration Guide

Complete guide to managing app features via remote JSON configuration files.

## 📍 Configuration Files

Three JSON configuration sources control the app:

### **1. Asset Config** (Base/Fallback)
- **File**: `assets/app_config.json`
- **Purpose**: Initial configuration loaded at startup. Serves as the ultimate fallback if remote configs are unreachable.

### **2. Main Config** (Primary Remote)
- **URL**: `https://api.singhs.com.np/api/main-config.json`
- **Purpose**: Primary app configuration source.

### **3. Alt Config** (Secondary Remote)
- **URL**: `https://api.singhs.com.np/api/alt-config.json`
- **Purpose**: Used if main config fails to load.

## 🔄 Config Loading Strategy

```
App Starts
    ↓
Load: assets/app_config.json (Initial State)
    ↓
Try: GET main-config.json
    ↓
Success? → Merge into state → Done ✅
    ↓
Fail? → Try: GET alt-config.json
    ↓
Success? → Merge into state → Done ✅
    ↓
Fail? → Stay with Asset Config values
```

## 📋 Configuration Parameters

### **App Control Flags**

```json
{
  "review_mode": false,
  "streaming_enabled": true,
  "ads_enabled": true,
  "banner_enabled": true,
  "rewarded_enabled": true,
  "app_open_enabled": true,
  "interstitial_enabled": true
}
```

| Parameter | Type | Purpose | Values |
|-----------|------|---------|--------|
| `review_mode` | boolean | Disable ads for store review | true/false |
| `streaming_enabled` | boolean | Show streaming links | true/false |
| `ads_enabled` | boolean | Master ad switch | true/false |
| `banner_enabled` | boolean | Banner ads in lists | true/false |
| `rewarded_enabled` | boolean | Rewarded ads | true/false |
| `app_open_enabled` | boolean | Ad on app resume | true/false |
| `interstitial_enabled` | boolean | Full-screen ad on match detail | true/false |

### **AdMob Ad Unit IDs**

```json
{
  "banner_ad_id": "ca-app-pub-5525538810839147/3825132304",
  "rewarded_ad_id": "ca-app-pub-5525538810839147/6942250234",
  "app_open_ad_id": "ca-app-pub-5525538810839147/1223019695",
  "interstitial_ad_id": "ca-app-pub-5525538810839147/4446428920"
}
```

### **Maintenance & Messages**

```json
{
  "maintenance_mode": false,
  "maintenance_message": "App is under maintenance. Please try again later.",
  "app_message": "Welcome to YoSinTV!",
  "app_message_type": "info"
}
```

| Parameter | Type | Purpose | Notes |
|-----------|------|---------|-------|
| `maintenance_mode` | boolean | Block all navigation | true → Show maintenance screen |
| `maintenance_message` | string | Message to display | Max 200 characters |
| `app_message` | string | Announcement banner | Empty string = no banner |
| `app_message_type` | string | Banner color | "info" / "warning" / "error" |

### **Social Links**

```json
{
  "whatsapp_link": "https://wa.me/1234567890",
  "telegram_link": "https://t.me/yosintv"
}
```

### **API Endpoints**

```json
{
  "football_api_url": "https://api.singhs.com.np/api/football-matches.json",
  "cricket_api_url": "https://api.singhs.com.np/api/cricket-matches.json",
  "articles_api_url": "https://api.singhs.com.np/api/articles.json",
  "alt_config_url": "https://api.singhs.com.np/api/alt-config.json"
}
```

## 🎯 Common Use Cases

### **Scenario 1: Disable Ads During App Review**

**Current config:**
```json
{
  "ads_enabled": true,
  "review_mode": false
}
```

**For App Store/Play Store Review:**
```json
{
  "review_mode": true,
  "ads_enabled": false
}
```

**Result:** ✅ Ads disabled, app can pass review
**Then restore after approval** ✅

---

### **Scenario 2: Maintenance Mode**

**Normal state:**
```json
{
  "maintenance_mode": false
}
```

**During server maintenance:**
```json
{
  "maintenance_mode": true,
  "maintenance_message": "We're updating our servers. Back in 2 hours!"
}
```

**Result:** 🔧 Users see maintenance screen, no navigation possible
**Automatically restores when you disable it** ✅

---

### **Scenario 3: Important Announcement**

**Add banner message:**
```json
{
  "app_message": "🔴 Live: Cricket World Cup Final - India vs Australia!",
  "app_message_type": "warning"
}
```

**Result:** ⚠️ Yellow banner shows on home screen

**Remove after event:**
```json
{
  "app_message": ""
}
```

---

### **Scenario 4: Change Ad IDs**

**Current ads:**
```json
{
  "banner_ad_id": "ca-app-pub-OLD_ID"
}
```

**New ad account:**
```json
{
  "banner_ad_id": "ca-app-pub-NEW_ID"
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

2. Update URLs in `assets/app_config.json`:
   "main_config_url": "https://server.com/api/main-config.json",
   "alt_config_url": "https://server.com/api/alt-config.json"
   
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
5. Update app URLs in `assets/app_config.json`
```

### **Option 3: GitHub** (Easy for testing)

```
1. Create config files in GitHub repo
2. Use Raw URLs:
   https://raw.githubusercontent.com/your-user/your-repo/main/config/main-config.json
3. Update app URLs in `assets/app_config.json`
```

### **Option 4: JSONBin.io** (Easy, no setup)

```
1. Go to https://jsonbin.io
2. Create new bin with JSON content
3. Get URL from "Share" button
4. Update app URLs in `assets/app_config.json`
```

---

## 📝 JSON Structure (Complete Example)

```json
{
  "review_mode": false,
  "streaming_enabled": true,
  "ads_enabled": true,
  "banner_enabled": true,
  "rewarded_enabled": true,
  "app_open_enabled": true,
  "interstitial_enabled": true,
  
  "banner_ad_id": "ca-app-pub-5525538810839147/3825132304",
  "rewarded_ad_id": "ca-app-pub-5525538810839147/6942250234",
  "app_open_ad_id": "ca-app-pub-5525538810839147/1223019695",
  "interstitial_ad_id": "ca-app-pub-5525538810839147/4446428920",
  
  "maintenance_mode": false,
  "maintenance_message": "App is under maintenance. Please try again later.",
  "app_message": "Welcome to YoSinTV v1.1.0!",
  "app_message_type": "info",
  
  "whatsapp_link": "https://wa.me/1234567890",
  "telegram_link": "https://t.me/yosintv",
  
  "popup_enabled": false,
  "popup_title": "Welcome to YoSinTV",
  "popup_text": "Your daily sports companion!",
  
  "match_links": [],
  "articles": [],
  
  "football_api_url": "https://api.singhs.com.np/api/football-matches.json",
  "cricket_api_url": "https://api.singhs.com.np/api/cricket-matches.json",
  "articles_api_url": "https://api.singhs.com.np/api/articles.json",
  "alt_config_url": "https://api.singhs.com.np/api/alt-config.json"
}
```

---

## 🧪 Testing Config Changes Locally

### **Method 1: Modify Assets**
Edit `assets/app_config.json` and rebuild:
```bash
flutter run
```

### **Method 2: Host Locally (Python)**
```bash
cd config/
python -m http.server 8000
```

Then update URLs in `assets/app_config.json` to `http://localhost:8000/main-config.json`

### **Method 3: Use Online JSON Hosting**
1. Copy JSON to https://jsonbin.io
2. Get shareable URL
3. Update app URLs temporarily in `assets/app_config.json`
4. Test changes

---

## 🎛️ Control Matrix

| Feature | Config Key | On | Off |
|---------|-----------|----|----|
| **Ads (All)** | ads_enabled | Ads show | No ads |
| **Banner Ads** | banner_enabled | Every 3 items | No banners |
| **Interstitial** | interstitial_enabled | Match detail | Skip fullscreen ad |
| **App Open** | app_open_enabled | On resume | Skip resume ad |
| **Streaming** | streaming_enabled | Show links | Hide links |
| **Review Mode** | review_mode | No ads | Ads enabled |
| **Maintenance** | maintenance_mode | Block app | Normal |

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

**To change:** Update `assets/app_config.json`

---

## 🚨 Error Handling

**If main-config fails:**
```
App tries alt-config.json → If alt fails → Stays with assets/app_config.json values
```

**This ensures app always works**, even if both remote configs are down!

---

## 📱 Real-World Example

### Morning Deployment:
```json
{
  "app_message": "🔴 LIVE NOW: India vs Pakistan Cricket!",
  "app_message_type": "warning"
}
```

### Evening:
```json
{
  "app_message": "📊 Match Highlights: India wins by 50 runs!",
  "app_message_type": "info"
}
```

### Before App Review:
```json
{
  "review_mode": true,
  "ads_enabled": false
}
```

### After Approval:
```json
{
  "review_mode": false,
  "ads_enabled": true
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

If hosting configs on different server, update `assets/app_config.json`:
```json
  "main_config_url": "YOUR_CONFIG_URL/main-config.json",
  "alt_config_url": "YOUR_CONFIG_URL/alt-config.json"
```

Then rebuild app:
```bash
flutter run
```

---

**Your app is now fully controlled via these JSON files!** 🎉

Make changes anytime → Users get updates on next app launch → No Store update needed!
