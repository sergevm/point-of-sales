# App Store Connect screenshots

Ready-to-upload screenshots for App Store Connect, taken from the simulator in
Dutch (`nl-BE`) with demo data.

## Sizes and limits

App Store Connect accepts **at most 10 screenshots per device size** per
localization. These sets stay within that limit:

| Folder | Device | Pixels | Connect display size |
|---|---|---|---|
| `iphone-6.9/` (9 shots) | iPhone 17 Pro Max | 1320 × 2868 portrait | iPhone 6.9" (required) |
| `ipad-13/` (10 shots) | iPad Pro 13" (M5) | 2752 × 2064 landscape | iPad 13" (required for iPad apps) |

Smaller display sizes (6.5", 12.9", …) are scaled down from these automatically
by App Store Connect, so no extra sets are needed.

## Suggested upload order

Lead with the shots that sell the app at a glance:

1. Register with a live ticket (`*-01-register`)
2. Payment dialog with per-method totals (`*-02/03-payment`)
3. Last-order panel (`*-03/04-last-order`)
4. Session sales list (`*-04/05-sales`)
5. Session report (`*-05/07-report`)
6. Daily receipts (`*-06-daily`)
7. Configuration (`ipad-07-configure`, `ipad-08-products`)
8. Start screen (`*-start`)

## Regenerating

The app seeds demo content when a **debug build** is launched with the
`-demoData` argument (see `PointOfSales/Support/DemoData.swift`): the
"Vrolijke vrienden vzw" organization, four categories with products, a closed
session with a full evening of orders, and an open session. On iPad add
`-demoLandscape` to rotate the simulator to landscape.

```sh
xcrun simctl install <udid> <path-to>/PointOfSales.app
xcrun simctl status_bar <udid> override --time "09:41" --batteryState charged --batteryLevel 100 --wifiBars 3 --cellularBars 4
xcrun simctl launch <udid> com.sergevm.PointOfSales -demoData -demoLandscape
xcrun simctl io <udid> screenshot shot.png
```

iPad screenshots come out of `simctl` portrait-oriented; rotate them with
`sips -r 90 shot.png`. `simctl` writes PNGs **with an alpha channel, which App
Store Connect rejects** — flatten to RGB before uploading (Pillow:
`Image.merge('RGB', im.convert('RGBA').split()[:3])`; the checked-in files are
already flattened). Device frames/bezels are optional; plain full-screen
captures like these are accepted as long as they show the real app in use
(App Review guideline 2.3.3). The web-sized copies used by the support site
live in `site/screenshots/`.
