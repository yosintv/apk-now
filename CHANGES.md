# YoSinTV — Session Changelog

All changes made during the UI/UX overhaul and feature session.  
App version brought from **1.1.0** → **1.1.2** (`pubspec.yaml: 1.1.2+3`).

---

## 1. Full UI/UX Overhaul — FotMob / Cricbuzz Quality

A complete visual redesign of all 9 primary UI files targeting a premium, professional sports-app feel.

### `lib/theme/app_colors.dart`
Extended the design token system with a full set of named colour constants used consistently across the app:

| Token | Purpose |
|---|---|
| `live` | Red pulse for live match indicators |
| `upcoming` | Amber for scheduled matches |
| `football` / `footballLight` | Sport colour pair for football |
| `cricket` / `cricketLight` | Sport colour pair for cricket |
| `news` / `newsLight` | Purple pair for news section |
| `telegram` / `whatsapp` | Social button colours |
| `drawerBackground` / `drawerGradientStart` / `drawerGradientEnd` | Drawer dark gradient |
| `inactiveTab` | Unselected nav bar icon/label |
| `border` / `divider` | Subtle separators |
| `textPrimary` / `textSecondary` / `textMuted` | 3-tier text hierarchy |

---

### `lib/widgets/match_card.dart`
Redesigned from scratch as a premium dark card:
- Dark navy gradient background (`#0B1437 → #0F1B4D`)
- Team logos with white circular background containers
- Sport badge (Football / Cricket) with colour-coded dot
- Score display shown only during live/finished matches
- Live minute indicator (e.g. `45'`) with pulsing red dot
- Countdown timer shown for upcoming matches
- League name + logo in card header
- Stadium name in footer
- `withValues(alpha:)` used everywhere (no deprecated `withOpacity`)

---

### `lib/widgets/news_card.dart`
Two distinct layouts controlled by the `featured` boolean parameter:

**Featured card** (`featured: true`):
- Full-width top image (182px) with gradient scrim overlay
- Category badge floating on the image (top-left)
- Bold 16pt title with 2-line clamp
- Timestamp + "Read more →" footer row

**Compact card** (`featured: false`):
- Left colour accent bar (3px, category colour)
- Inline category chip with soft tinted background
- 13pt title with 2-line clamp
- 92px right thumbnail
- `IntrinsicHeight` + `Row(crossAxisAlignment: stretch)` for matched heights

**Image placeholder** (`_imagePlaceholder`):
- Shows `assets/logo.png` on a dark navy (`#06113D`) background instead of a generic icon
- Falls back to `Icons.live_tv_rounded` if the asset fails to load
- Maintains brand consistency when API images are unavailable

---

### `lib/screens/main_shell.dart`
- Material 3 `NavigationBar` with `WidgetStateProperty` for per-state label/icon theming
- White nav bar with `#0F000000` top shadow
- Fixed height 62px, `alwaysShow` labels
- `scrolledUnderElevation: 1.5` on `AppBar` for subtle scroll shadow
- Header logo from `assets/headerimage.png` (falls back to text)
- Full-width drawer (284px) with:
  - Purple gradient header containing logo, app name, tagline pill
  - Animated selected-state tile highlight (`AppColors.accent` at 90% alpha)
  - White dot active indicator on selected tile
  - Telegram + WhatsApp social buttons at bottom
  - Version string in footer (now dynamic — see version section)

---

### `lib/main.dart` — Theme
Full Material 3 theme applied to `MaterialApp.router`:
- `ColorScheme.fromSeed(seedColor: AppColors.primary)`
- `GoogleFonts.interTextTheme` for all text
- `NavigationBarThemeData` with `WidgetStateProperty` for icon/label colours
- `ChipThemeData` with rounded 18px radius
- `CardThemeData` with zero elevation and 16px radius
- `DividerThemeData` at 1px thickness

---

### `lib/screens/home/home_screen.dart`
- **Stats bar** at top: LIVE count pill + UPCOMING count pill + total match count (right-aligned)
- **Search bar** with clear button, rounded 14px, subtle shadow
- **Horizontal filter chips**: All / Cricket / Football + dynamic league labels extracted from live data (IPL, UCL, La Liga, etc.)
- **LIVE NOW** section with section header showing live count badge
- **Upcoming** section with section header
- **Inline `AdBannerWidget`** every 4 match cards in the upcoming list
- **Latest News** section at bottom: first article as featured card, next 4 as compact cards
- Sort order: LIVE → UPCOMING (soonest first) → FINISHED

---

### `lib/screens/football_screen.dart`
- Matches grouped by competition/league
- Collapsible competition header with league logo + match count badge
- `RefreshIndicator` with `AppColors.football` colour
- Live pulse indicator on cards
- Empty state and error state with retry button

---

### `lib/screens/cricket_screen.dart`
- Same competition-group pattern as football
- `RefreshIndicator` with `AppColors.cricket` colour
- Format tag (e.g. T20, ODI, Test) from league name
- Same empty/error states

---

### `lib/screens/news_screen.dart`
- Purple gradient header (`#1A0533 → #5B21B6`) with article count + LIVE badge
- Horizontal category filter chips: All / Football / Cricket / Transfer / Injury
  - Only shows categories that have at least one article
- "Latest Stories" section header with `AppColors.news` count badge
- First article rendered as `NewsCard(featured: true)` (large image card)
- Remaining articles as `NewsCard()` compact — ad every 5 slots (4 articles + 1 `AdBannerWidget`)
- `RefreshIndicator(color: AppColors.news)`
- Empty state for no articles, separate empty state for no filter match
- Error state with `AppColors.news` retry button

---

## 2. Null Check Red Screen Fix

**Problem:** App showed a red error screen for 1–2 seconds on startup.

**Root cause:** `_YoSinTVAppState.build()` returned `MaterialApp(home: LoadingScreen())` during loading and then switched to `MaterialApp.router(...)` once loading was done. This caused `rootNavigatorKey` to briefly detach from its `Navigator`, triggering a null-check crash inside `go_router`.

**Fix** (`lib/main.dart`):
- Removed the conditional `MaterialApp` / `MaterialApp.router` split entirely
- Now always returns a single `MaterialApp.router` from the first frame
- Added `builder:` parameter to overlay `LoadingScreen` as a `Stack` on top of the router's child tree:

```dart
builder: (context, child) {
  return Stack(
    children: [
      child ?? const SizedBox.shrink(),
      if (_splashVisible)
        AnimatedOpacity(
          opacity: _isLoading ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          onEnd: () {
            if (!_isLoading && mounted) setState(() => _splashVisible = false);
          },
          child: const LoadingScreen(),
        ),
    ],
  );
},
```

Two booleans control this:
- `_isLoading` — triggers the 500ms fade-out when set to `false`
- `_splashVisible` — set to `false` only after the fade completes, removing the widget from the tree

---

## 3. Animated Splash Screen (Single Screen)

**Problem:** Two splash screens — Android XML layer (showed icon on white) then Flutter loading screen (dark navy). Looked like two different apps.

**Fix:**
- `android/app/src/main/res/drawable/launch_background.xml` — changed to plain `#FF050E2E` solid colour (no logo, no white)
- `android/app/src/main/res/drawable-v21/launch_background.xml` — same change
- Flutter `LoadingScreen` (`lib/widgets/loading_screen.dart`) completely rewritten as `StatefulWidget` with `TickerProviderStateMixin` and 4 animation controllers:

| Controller | Duration | What it animates |
|---|---|---|
| `_logoCtrl` | 900ms | Logo fade-in + elastic scale (`0.55 → 1.0`, `elasticOut`) |
| `_textCtrl` | 600ms | App name + subtitle fade + 20px slide up (starts at 350ms) |
| `_barCtrl` | 2200ms | Progress bar `0.0 → 0.9` (starts at 650ms) |
| `_floatCtrl` | 2000ms repeating | Logo floats `0 → -10px` vertically (reverse loop) |

**Visual spec:**
- Background: deep navy gradient `#050E2E → #091A4A → #0D2460`
- 112×112 white circle logo with blue glow `boxShadow`
- "YoSinTV" at 38pt bold white, letter-spacing -1.2
- "24/7 · Football & Cricket" in a frosted pill (`7% white bg, 12% white border`)
- 3px slim `LinearProgressIndicator` (blue → light-blue colour lerp)
- "LOADING" caption at 10pt, 2.5 letter-spacing, 25% white opacity

---

## 4. Smooth Screen Transitions

**Problem:** Tab switches were instant (jarring jump). Push routes used Flutter's default platform slide.

### Tab switching — `lib/screens/main_shell.dart`
Added `_BranchFader` stateful widget that wraps `navigationShell`:
- Tracks `currentIndex`
- On every index change: replays a `0.0 → 1.0` fade animation (180ms, `Curves.easeOut`)
- Does **not** unmount branches — `IndexedStack` state is fully preserved
- `NavigationBar.animationDuration` reduced from 300ms → 200ms for snappier indicator

```dart
class _BranchFader extends StatefulWidget { ... }
// Used in build:
body: _BranchFader(
  index: navigationShell.currentIndex,
  child: navigationShell,
),
```

### Push routes — `lib/router.dart`
Both `/match-detail` and `/article-detail` changed from `builder:` to `pageBuilder:` with `CustomTransitionPage`:
- **Enter:** subtle 5% slide-up + fade-in over 300ms (`Curves.easeOutCubic`)
- **Exit:** fade-out over 220ms (faster dismiss feels natural on back gesture)

---

## 5. Match Links — 15-Minute Pre-Match Activation

Confirmed already implemented in `lib/screens/match_detail/match_detail_screen.dart` (lines 140–143). No code changes needed.

```dart
final isPreMatch = status == MatchStatus.upcoming &&
                   countdown != null &&
                   countdown.inMinutes <= 15;
// Links shown when: status == MatchStatus.live || isPreMatch
```

Placeholder text shown to user: *"Streaming links appear 15 minutes before kick-off."*

---

## 6. Version Bump — 1.1.0 → 1.1.2

| File | Change |
|---|---|
| `pubspec.yaml` | `version: 1.1.0+2` → `version: 1.1.2+3` |
| `lib/screens/main_shell.dart` | Drawer footer text: `"Version 1.1"` → `"Version 1.1.2"` |

---

## 7. EU Consent — Google UMP (GDPR / TCF 2.2)

**File:** `lib/main.dart`

Added `_gatherConsent()` method that runs **before** `MobileAds.instance.initialize()` on every cold start.

**Flow:**
1. `ConsentInformation.instance.requestConsentInfoUpdate()` — determines if user is in EEA/UK
2. If consent form is available → `ConsentForm.loadAndShowConsentFormIfRequired()` shows the standard Google GDPR consent dialog
3. `MobileAds.instance.initialize()` is called only after consent is resolved
4. 12-second safety timeout ensures a network failure never blocks startup
5. On any error → continues silently; AdMob falls back to non-personalised ads (still policy-compliant)

**Non-EEA users** (most of the audience) pass through instantly with zero delay.

**Key rule:** Always call `_gatherConsent()` before `MobileAds.instance.initialize()`. Never reverse this order.

---

## 8. App Message Banner

A remote-controlled announcement banner shown on the Home screen below the filter chips.

### Config fields (`main-config.json`)
```json
{
  "app_message_enabled": true,
  "app_message": "Welcome to YoSinTV v1.1.2! Enjoy live football & cricket.",
  "app_message_type": "info"
}
```

### Supported types
| `app_message_type` | Background | Accent colour | Icon |
|---|---|---|---|
| `"info"` | `#EFF6FF` | `AppColors.primary` (blue) | `info_outline_rounded` |
| `"warning"` | `#FFFBEB` | `#F59E0B` (amber) | `warning_amber_rounded` |
| `"success"` | `#ECFDF5` | `#10B981` (green) | `check_circle_outline_rounded` |
| `"error"` | `#FEF2F2` | `#EF4444` (red) | `error_outline_rounded` |

### Files changed
- **`lib/models/app_config.dart`** — Added `appMessageEnabled` field, parsed from `app_message_enabled` JSON key. Added to constructor, `AppConfig.empty()`, `fromJson()`, and `toJson()` / `merge()`.
- **`lib/screens/home/home_screen.dart`** — Added `_messageDismissed` boolean state. Added `SliverToBoxAdapter` sliver between filter chips and Live Now section. Added `_buildAppMessage(String message, String type)` method.

### Behaviour
- Renders only when `appMessageEnabled == true` AND `appMessage.isNotEmpty`
- User can dismiss with the `×` button — uses `AnimatedSize(duration: 250ms)` to collapse smoothly
- Dismissal is **session-only** (in-memory `_messageDismissed` flag) — banner reappears on next cold start if still enabled in config
- To hide immediately for all users: set `"app_message_enabled": false` in the remote config

---

## AdMob Placement Reference

| Ad Format | Widget | Location | Notes |
|---|---|---|---|
| Sticky banner | `BannerAdWidget` | `MainShell` bottom (above nav bar) | Persistent on all tabs |
| Adaptive banner | `AdBannerWidget` | Home screen — inline in match list | Every 4 match cards |
| Adaptive banner | `AdBannerWidget` | Football screen — 2 placements | Spaced between competition groups |
| Adaptive banner | `AdBannerWidget` | Cricket screen — 2 placements | Spaced between competition groups |
| Adaptive banner | `AdBannerWidget` | News screen — inline in article list | Every 5 articles |
| Banner | `BannerAdWidget` | Match detail screen — bottom bar | |
| Banner | `BannerAdWidget` | Article detail screen — body | |
| App Open | `AdService.loadAppOpenAd` | Cold start + app resume | `showImmediately: true` on first load; shown on `didChangeAppLifecycleState(resumed)` |
| Interstitial | `AdService.showInterstitialAd` | Match card tap | After 4 clicks, min 2-minute interval between shows |
| Rewarded | `AdService.showRewardedAd` | Match detail screen | Unlocks streaming links |

`BannerAdWidget` uses fixed `AdSize.banner` (320×50).  
`AdBannerWidget` uses `AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize` for a responsive fit.

---

## File Change Summary

| File | Type of change |
|---|---|
| `pubspec.yaml` | Version bump 1.1.0+2 → 1.1.2+3 |
| `lib/main.dart` | Null-check fix (single MaterialApp.router), EU consent (_gatherConsent), Material 3 theme |
| `lib/router.dart` | CustomTransitionPage for /match-detail and /article-detail push routes |
| `lib/theme/app_colors.dart` | Extended design token set |
| `lib/models/app_config.dart` | Added appMessageEnabled field |
| `lib/screens/main_shell.dart` | _BranchFader, nav animation 300ms→200ms, Material 3 nav bar, drawer, version string |
| `lib/screens/home/home_screen.dart` | Stats bar, search, filter chips, app message banner, news section |
| `lib/screens/football_screen.dart` | Competition-grouped redesign |
| `lib/screens/cricket_screen.dart` | Competition-grouped redesign |
| `lib/screens/news_screen.dart` | Category filter, featured + compact list, inline ads |
| `lib/widgets/match_card.dart` | Dark premium card redesign |
| `lib/widgets/news_card.dart` | Featured + compact variants, logo placeholder |
| `lib/widgets/loading_screen.dart` | Full rewrite — 4-controller animated splash |
| `android/.../drawable/launch_background.xml` | Plain #FF050E2E (no logo, no white) |
| `android/.../drawable-v21/launch_background.xml` | Same as above |
