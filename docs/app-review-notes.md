# App Review Information — Notes for App Store Connect

Paste the block below into **App Store Connect → App → App Review Information →
Notes**, then attach the physical-device screen recording described in the second
section. Fill in the exact device models and OS versions at the bottom before
submitting.

> **Note on scope:** This describes build **1.0 (1)** as submitted (from
> `release/1.0.0`), which sets up the catalog **manually** (there is no one-tap demo
> in this build). A later build on `main` adds a one-tap "demo setup"; if you ever
> submit that build, update the setup steps accordingly.

---

## Notes text (paste this)

**App purpose & audience**
PointOfSales is a simple, fully offline point-of-sale (cash register) app for small
Belgian businesses and non-profit associations — for example a club/association bar, a
pop-up stand, or a market stall. One person runs sales on a single iPhone or iPad: open
a sales session, tap products to build an order, record the payment (cash / card /
Payconiq), and at the end of the session produce a summary report (PDF/CSV) that can be
emailed to a bookkeeper. It includes a helper for Belgian daily-receipts bookkeeping
(dagontvangstenboek). It solves the tracking of bar/stand sales and end-of-day totals
without expensive POS hardware or a subscription.

**How to set up and access the main features (no login required)**
There is no account or login; all data is stored locally on the device. On first launch
the catalog is empty, so you first create a category and a few products:
1. Launch the app. The "No open session" start screen appears.
2. Tap **"Add categories and products first"** to open the Configuration screen.
3. Tap **"Add category"** (the **+** in the top-right), give it a name (e.g. "Drinks")
   and a colour, and save.
4. Tap the new category row, then tap **"Add product"** (the **+**), enter a product
   name and price, and save. Add two or three products this way.
5. Tap **"Done"** to close Configuration, then tap **"Start session"**.
6. In the register, tap products to add them to the cart, adjust quantities, then charge
   the order and choose a payment method (Cash / Card / Payconiq).
7. Open **Sales** to review the session's orders; open the **session report** to
   generate a PDF/CSV summary and optionally email it via the system Mail sheet.
8. End the session from the session menu.

No demo credentials are needed — the app has no login/account.

**External services / tools / platforms**
None. The app is fully offline and uses only Apple system frameworks (SwiftUI, SwiftData
for on-device storage, MessageUI for the optional email-a-report sheet). There is no
backend, no network calls, no third-party SDKs, no analytics, no authentication service,
and no payment processor. The payment method is only recorded as a label for reporting —
the app does NOT process or transmit any payment.

**Accounts / paid content / user content / permissions**
- No account registration, login, or account deletion (no accounts at all).
- No in-app purchases, subscriptions, or paid content — the app is free and fully
  functional.
- No user-generated content shared between users (all data is local, single device).
- No requests for sensitive data or device capabilities: no camera, location, contacts,
  photos, microphone, or App Tracking Transparency. No permission dialogs appear anywhere
  in the app.

**Regional differences**
The app functions consistently across all regions. The interface is localized in English
and Dutch (following the device language); currency is EUR. The Belgian daily-receipts
helper is built-in arithmetic, not a connection to any government or regulated service.

**Regulated industry / third-party material**
Not applicable. The app does not operate in a regulated industry and includes no
protected third-party material. It does not process payments, file taxes, or connect to
any authority — it only produces local reports the owner can keep or email to their own
bookkeeper.

**Devices & OS tested**
- iPhone «model», iOS «version»
- iPad «model», iPadOS «version»

---

## Screen recording shot list (record on a PHYSICAL device)

Apple requires a real device running the latest OS — simulator recordings are rejected.
Record ~1–2 minutes on the iPhone (and optionally repeat on the iPad); no narration
needed:

1. Cold-launch the app from the Home screen → the "No open session" start screen appears.
2. Tap **"Add categories and products first"** → Configuration opens.
3. Tap **"Add category"** (+) → name it (e.g. "Drinks"), pick a colour, save.
4. Tap the category → tap **"Add product"** (+) → enter a name and price, save. Repeat
   for one or two more products.
5. Tap **"Done"**, then tap **"Start session"**.
6. Tap a few products to build a cart; change one quantity.
7. Charge the order → select a payment method (e.g. Cash).
8. Add a second order to show repeat use.
9. Open **Sales** → show the session's order list.
10. Open the **session report** → show the PDF/CSV summary (optionally open the
    Mail/Share sheet, then cancel).
11. End the session.

Note: no login and no permission prompts appear, so there is nothing gated to
demonstrate.
