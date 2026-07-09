# App Store submission checklist

What's already handled in the project, and what still has to happen in
App Store Connect (manual steps) before the app can go to Apple review.

## Done in the project (2026-07-06)

- `PrivacyInfo.xcprivacy`: no tracking, no data collection, no required-reason APIs.
- `ITSAppUsesNonExemptEncryption = NO` in build settings — no export-compliance
  question at every upload.
- App icon converted to 8-bit sRGB PNG, no alpha (App Store Connect rejects
  non-standard icon PNGs).
- Full Dutch (nl) localization via `Localizable.xcstrings`, English source.
  Proper plural forms for item/order counts.
- Save failures, PDF/CSV generation failures surfaced to the user; destructive
  actions (delete category/product, clear ticket) require confirmation.
- Category deletion keeps products (unassigned) with a re-assign flow.

## To do in App Store Connect (manual)

1. **App record**: bundle id `com.serge.PointOfSales`, name, subtitle,
   category *Business*, price Free (presumably).
2. **Privacy policy URL** — hosted on GitHub Pages (source in `site/`,
   deployed by `.github/workflows/pages.yml`):
   `https://sergevm.github.io/point-of-sales/privacy.html`
3. **App Privacy questionnaire**: answer "Data Not Collected".
4. **Support URL**: `https://sergevm.github.io/point-of-sales/`
5. **Screenshots**: the app now targets iPhone and iPad, so both sets are
   required: iPhone 6.9" (1320×2868 or 2868×1320) and iPad 13" (2064×2752 or
   2752×2064, landscape). Use realistic demo data; the simulator flow used
   for testing works fine for this.
6. **Export compliance**: already answered by the Info.plist key; if asked,
   the app uses no encryption beyond Apple's OS encryption.
7. **App Review notes** (important — the app launches empty):
   > The app is a point-of-sale register for a small non-profit and starts
   > with no data by design. To try it: Configure (sliders icon) → add a
   > category → open it → add a product with a price → close configuration →
   > Start session → tap the product → Charge → pick a payment method.
   > Ending a session (Sales icon → End session) produces the numbered report
   > that can be emailed/shared as PDF/CSV.
8. **Age rating**: fill the questionnaire (nothing sensitive → 4+).
   Note: the app is about selling in general; alcohol is not referenced by
   the app itself, only by whatever product names the user enters.
9. Archive with a distribution certificate (Automatic signing, team
   W2J4926FDW) and upload via Xcode Organizer.

## Deferred polish (known, intentional — not blocking review)

- Haptics/`sensoryFeedback` after charge and void.
- Adaptive cart panel width (fixed 340 pt in `RegisterView`); toolbar
  `.fixedSize` reflow on narrow widths.
- Icon fill-style consistency (filled +/− steppers vs outline trash).
- Larger colour swatch tap targets in the configuration category row.
- `ContentUnavailableView` for the empty closed-sessions list.
- Configurable currency (hardcoded EUR in `Money.swift`).
- Enterprise-number format validation.
- Custom launch screen branding (currently system default).
- Dynamic Type audit (`@ScaledMetric` for fixed frames).
- `maxWidth: 700` report layout on very wide iPads.
