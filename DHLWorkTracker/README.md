# DHL Work Tracker

A minimal native iPhone app for privately tracking work hours and estimating gross pay. The app is independent and does not use DHL branding, accounts, analytics, GPS, OCR, or a backend.

## Open and Run

1. Open `DHLWorkTracker.xcodeproj` in Xcode 15 or newer.
2. Select an iPhone simulator running iOS 17 or newer.
3. Run the `DHLWorkTracker` scheme.
4. Run unit tests with `Product > Test`.

All data is stored locally with SwiftData.

## Architecture

- SwiftUI views are split into the four required tabs: Vandaag, Geschiedenis, Overzicht, Instellingen.
- SwiftData models live in `DHLWorkTracker/Models`.
- Payroll formulas live in `PayrollEngine`, outside the UI.
- `TodayViewModel` handles starting a shift, switching activities, undo, and finishing.
- XCTest coverage lives in `DHLWorkTrackerTests`.

## Calculation Rules

- Every activity is paid by default except `Pauze`.
- Breaks are never automatically deducted. They only reduce paid time when marked unpaid.
- The app selects the hourly rate by the shift date.
- Saturday hours get the configured Saturday allowance.
- Sunday and recognised holiday hours get the configured Sunday/holiday allowance.
- Holiday allowance and vacation-day payout are calculated separately.
- A configurable minimum attendance rule can raise base paid hours to 3 hours for short attendances.
- Shifts crossing midnight are split by calendar day before allowances are calculated.
- Money is calculated with `Decimal` and rounded to cents.

Default rates:

- 1 July 2025: €15.03
- 1 January 2026: €15.33
- 1 July 2026: €15.64
- 1 January 2027: €15.88
- 1 July 2027: €16.11

## Changing Rates

Open Instellingen and edit the hourly-rate history. Existing timestamps are kept; recalculation uses the current settings and stored activity times.

## CSV Export

Open Instellingen and use Export CSV. iOS opens the share sheet with all saved shifts.

## Known Limitations

- The requested spreadsheets and CAO PDF were not available in this workspace session, so the initial settings follow the values provided in the pasted brief.
- Simulator screenshots and a real Xcode build/test run require macOS with Xcode. This project was authored in the shared workspace, but this Windows environment cannot launch iOS Simulator.
- Recognised holidays are supported by the payroll engine through a holiday-date set, but a full Dutch holiday calendar UI is not included in this MVP.
