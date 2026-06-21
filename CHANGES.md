# YoSinTV — Changelog

## v1.2.0 (2026-06-21)
- AdMob match rate: sports keywords + content URL on every `AdRequest`
- AdMob: `RequestConfiguration` with `maxAdContentRating.ma` + no child-directed flag (max inventory)
- `BannerAdWidget`: now waits for SDK init before loading (fixes pre-init rejected requests)
- `BannerAdWidget`: retries failed loads after 5 s; `AdBannerWidget` retry reduced 15 s → 5 s
- Ad load moved to `initState` via `addPostFrameCallback` (earliest possible moment)
- Fixed huge ad padding: switched from `getLargeAnchoredAdaptiveBannerAdSize` to `AdSize.banner` (exact 50 px, no internal whitespace)
- News section added to Football + Cricket screens (shown when no matches, or appended at bottom)
- `AutomaticKeepAliveClientMixin` on all 4 tab screens + `AdBannerWidget` (prevents re-fetch on tab switch, keeps ads alive while scrolled off)
- `RepaintBoundary` around match cards (isolates repaints, reduces jank)
- `review_mode: true` — hides ALL match/streaming links (store-review safety); ads unaffected
- `streaming_enabled: false` — hides streaming links only; ads unaffected
- `rewarded_ad_id_time` config param — controls seconds before rewarded ad shows in match detail
- Ads now gated only by `ads_enabled`; `review_mode` no longer suppresses ads
- Banner ad in match detail always shows (moved outside `shouldShowLinks` block)
- Sidebar + `pubspec.yaml` version bumped `1.1.2+3` → `1.2.0+4`

## v1.1.2 (previous session)
- Push notifications 15 min before each upcoming match (football + cricket)
- Match detail: white AppBar with logo, banner ad above links, links hidden for finished matches
- Ad every 3 match cards across home, football, cricket (was 4)
- Removed redundant league headers in football/cricket screens
- Faster banner ad loading via `ref.listen(adSdkInitializedProvider)`

## v1.1.0 (UI/UX overhaul)
- Full redesign — premium dark match cards, animated splash, smooth transitions
- EU GDPR consent via Google UMP (runs before AdMob init)
- Home: stats bar, search, filter chips, app message banner
- Football/Cricket: competition-grouped lists, live pulse, empty/error states
- News: category filter, featured + compact cards, inline ads
- Remote-controlled app message banner (4 types: info/warning/success/error)

---

## AdMob Placement Reference

| Format | Widget | Location |
|---|---|---|
| Sticky banner | `BannerAdWidget` | MainShell bottom — all tabs |
| Adaptive banner | `AdBannerWidget` | Home / Football / Cricket — every 3 cards |
| Adaptive banner | `AdBannerWidget` | News — every 5 articles |
| Adaptive banner | `AdBannerWidget` | Match detail — above links |
| App Open | `AdService` | Cold start + app resume |
| Interstitial | `AdService` | After 4 match taps, min 2-min gap |
| Rewarded | `AdService` | Match detail — unlocks stream links |
