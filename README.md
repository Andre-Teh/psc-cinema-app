# PSC Cinema

A Flutter mobile app for browsing movies, booking cinema seats, and ordering food & drinks, with separate dashboards for staff/managers and admins.

## Features

- **Authentication** — login, sign-up, and forgot-password flows backed by Firebase Auth
- **Multi-language support** — English and Chinese (switchable in-app via `flutter_localizations` / `.arb` files)
- **Movie browsing** — movie listings, movie details, trailers, and filtering
- **Seat booking flow** — seat selection, booking confirmation, and checkout
- **Food & drinks ordering** — add food/beverage items to an order alongside a ticket booking
- **Vouchers & promotions** — browse promotions, redeem vouchers and discounts
- **Membership & rewards** — membership screen with rewards/points tracking
- **Digital tickets with QR codes** — QR code generation for booking confirmations
- **Payment** — payment screen with support for e-wallet and bank transfer options
- **My Bookings** — view booking history
- **Notifications**
- **Profile management**
- **Cinema info** — cinema locations shown on Google Maps, plus About Us / Terms & Conditions pages
- **Manager dashboard** — film management (add/edit/list films), food & beverage management, staff dashboard, scheduling, and reporting (daily, F&B, movie, and ticket performance reports with charts)
- **Admin dashboard** — client management, order/payment data views, and configuration of bank/e-wallet types
- **PDF export** — generate/print PDF reports and receipts

## Tech stack

- **Flutter / Dart**
- **Firebase** — Firebase Auth, Cloud Firestore, Firebase Storage
- Google Maps (`google_maps_flutter`)
- Charts: `fl_chart`, `pie_chart`
- QR codes: `qr_flutter`, `qr_code_scanner`
- PDF generation: `pdf`, `printing`
- `flutter_localizations` + `intl` for English/Chinese localization
- `google_fonts`, `image_picker`, `fluttertoast`, `flutter_appauth`

## Screenshots

> Add your own screenshots to a `/screenshots` folder at the project root and update the paths below.

| Login | Home | Movie Booking |
|---|---|---|
| ![Login](screenshots/login.png) | ![Home](screenshots/home.png) | ![Booking](screenshots/booking.png) |

## Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart SDK `^3.7.2`, see `pubspec.yaml`)
- A Firebase project (Auth, Firestore, Storage enabled)

### Firebase setup

This repo does **not** include Firebase configuration files/keys (they're gitignored). To run the app, generate your own with the [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup):

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This will generate `lib/firebase_options.dart` and the platform config files (`android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, etc.) for your own Firebase project. Make sure Firebase Authentication (Email/Password) and Cloud Firestore are enabled in the Firebase console for your project.

### Run locally

```bash
flutter pub get
flutter gen-l10n   # generates the localization classes used throughout the app
flutter run
```

## Known limitations

This was built as a university assignment, not a production app. A few things worth calling out for anyone reading the code:

- **Staff account creation uses the client Firebase SDK.** The admin dashboard's "add client" feature calls `createUserWithEmailAndPassword` directly from the app instead of the Firebase Admin SDK, which means it briefly signs the app in as the newly-created user to write their profile. Public sign-up is restricted to creating `customer` accounts only (enforced in both the UI and the Firestore rules below); admin/manager accounts can only be created from the admin dashboard. A more robust version of this would move account creation to a Cloud Function.
- **Payment details are stored as plain text in Firestore** (`Payment_Data` collection) — card numbers, bank accounts, and e-wallet details are written directly, with no tokenization or PCI-style handling. This is fine for a course demo with fake payment data, but would need a real payment processor (Stripe, etc.) before handling real cards.
- **Firestore security rules** restrict access by sign-in state, document ownership, and role (`customer` / `manager` / `admin`, stored on each user's `Client` document) — see `firestore.rules`.

## Project background

Built as a university project at Asia Pacific University (APU).
