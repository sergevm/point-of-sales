# Point of Sale

A simple point-of-sale / cash register app for a small club bar, where orders are
taken at the bar on a single device. Built with SwiftUI and SwiftData. Runs on iPad
(landscape, with the ticket beside the register) and iPhone (with the ticket in a sheet
behind a bottom summary bar).

## Features

- **Sessions** — open a session to start recording sales, close it at the end of the night.
- **Cart-style ordering** — tap products to build a multi-item ticket with quantities and a
  running total, then **Charge** to record the order.
- **Categories & products** — configured in-app with persistent storage; each category has a
  colour used to tint its products on the register.
- **Session sales** — review every order recorded in the current session with its total.

Order line items snapshot the product name and price at charge time, so editing or deleting
a product later never alters past sales.

## Requirements

- Xcode 16+ (developed against Xcode 26)
- iOS 17+ iPhone or iPad (iPad is landscape-only)

## Running

Open `PointOfSales.xcodeproj` in Xcode, select an iPhone or iPad simulator (or device), and run.

## Project structure

- `PointOfSales/Models/` — SwiftData models: `ProductCategory`, `Product`, `SaleSession`,
  `Order`, `OrderItem`.
- `PointOfSales/Support/` — `Money` (currency formatting), `Cart` (in-memory ticket),
  `ColorHex` (category tinting).
- `PointOfSales/Views/` — register, configuration, and session-sales screens.

## Roadmap

- Browse / reopen previous sessions (the data model already distinguishes closed sessions).
- Payment methods and cash reconciliation.
