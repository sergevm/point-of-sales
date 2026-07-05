# Feature Plan — Point of Sales (Belgian vzw)

_Last updated: 2026-07-05_

## Business context

The app is an iPad point-of-sale for a **Belgian vzw** (non-profit association) operating under the
**small-business VAT exemption scheme** (vrijstellingsregeling kleine ondernemingen, turnover < €25,000/year).
Consequences:

- **No VAT is charged on sales** — no VAT rates or per-rate breakdowns are needed.
- Data is stored **locally** on the device (SwiftData). At the end of a register session a **report is
  emailed to the bookkeeper**.
- Products carry a **cost price** next to the selling price so net revenue / margin can be reported.

## Belgian legal obligations that shape the app

What **applies** to this vzw:

1. **Daily receipts record (dagontvangstenboek / dagboek van ontvangsten).** Required even under the
   exemption scheme for all sales without an invoice: one gross total per day, recorded daily,
   chronologically, **unalterable once recorded**. Individual tickets must be producible on inspection
   (the app snapshots every order, which satisfies this). Sales **over €250 per item must be recorded
   individually** — flagged in the daily view.
2. **Small-vzw simplified accounting** (KB 26/06/2003): the bookkeeper needs date, gross receipts per
   day/session, the **cash vs electronic split**, and corrections — this defines the report contents.
3. **Retention: 10 years** (since 2023). Reports and data must be exportable so retention doesn't
   depend on one iPad.
4. **Electronic payment option is mandatory** (since 1 July 2022) for enterprises dealing with
   consumers, including a vzw with economic activity → payment method is tracked per order.
5. **Cash rounding to 5 cents is mandatory** for cash payments in the customer's presence:
   1–2 → down, 3–4 → up to 5, 6–7 → down to 5, 8–9 → up. Optional for electronic payments.
6. **Invoices, when exceptionally issued** (B2B on request), must mention
   _"Bijzondere vrijstellingsregeling kleine ondernemingen"_ and the vzw's enterprise number.

What does **not** apply (consciously excluded):

- **VAT breakdowns** — exemption scheme. (If taxable turnover ever exceeds €25,000, VAT rates per
  product become required; the data model keeps this addable.)
- **GKS / witte kassa (registered cash system, incl. GKS 2.0)** — only mandatory for horeca above
  €25,000 food-service turnover. Note: if GKS ever applies, a home-built app cannot legally replace a
  certified system.
- **Peppol e-invoicing (1 Jan 2026 mandate)** — B2B only; B2C counter sales are out of scope, and
  exemption-scheme businesses don't have to send structured invoices.

## Features — implementing now (Phase 1)

| # | Feature | Why |
|---|---------|-----|
| A1 | **End-of-session report**: sequentially numbered, gross receipts, order count, per-category/product totals, payment-method breakdown, voided orders | Legal / bookkeeper needs |
| A2 | **Email report to bookkeeper**: mail composer with PDF + CSV attachments at session close | Core user goal |
| A3 | **Daily receipts view**: per-calendar-day totals across sessions, cash/electronic split, >€250 sales flagged | Dagontvangstenboek support |
| A4 | **Organization settings**: vzw name, address, enterprise number, bookkeeper email | Feeds reports |
| A5 | **Corrections**: void an order with a reason — audit trail instead of deletion; closed sessions immutable | Unalterability requirement |
| B1 | **Cost price per product**, snapshotted on order lines | Margin history survives price edits |
| B2 | **Net revenue / margin reporting** per session, product, category | User goal |
| C1 | **Payment method per order** (cash / card / Payconiq) | Legal cash-vs-electronic split |
| C2 | **Automatic 5-cent cash rounding**, adjustment stored on the order | Legal requirement |

## Features — future / optional

| # | Feature | Notes |
|---|---------|-------|
| C3 | Cash drawer counts (opening float, closing count, difference on report) | Strong candidate for Phase 2 |
| B3 | Dormant VAT rate per product | Activate if the vzw leaves the exemption scheme |
| B4 | Price history / effective dates | Snapshotting already protects history |
| D1 | Discounts (line/order level) | |
| D2 | Stock / inventory tracking | Ties into cost price (B1) |
| D3 | Customer receipt (AirPrint / on-screen) | No legal duty without GKS |
| D4 | Occasional B2B invoice generation with exemption wording | |
| D5 | Multi-device / cloud sync | Currently single-iPad |
| D6 | Cross-session dashboards (day/week/month/year) | |
| A6 | Full archive export (CSV/JSON) for 10-year retention | Partially covered by emailed reports |

## Features — excluded (not applicable)

| Feature | Reason |
|---------|--------|
| Full VAT regime (rates, per-rate dagontvangsten) | Exemption scheme; B3 keeps the door open |
| GKS / witte kassa compliance | Not applicable; legally impossible for a home-built app anyway |
| Peppol e-invoicing | B2B-only mandate, out of POS scope |
| Multiple concurrent registers | Single-iPad use case |
