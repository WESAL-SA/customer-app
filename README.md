# Wesal — Customer (Rider) App

Flutter app for the Wesal Saudi ride-hailing platform. Built **UI-first against a
mock service layer**, structured so the real backend can be connected later
**without rewriting the UI**.

> **Status (important, read this first).** This is **phase 1: a foundation + the
> core booking→trip→rating flow**, not a finished production app. It runs entirely
> on an **in-memory mock backend** because the real Wesal backend services did
> not exist when this was built (the `customer-app` repo was empty and the
> `api-and-backend`, `realtime`, `dispatch-engine`, `payments-engine` repos were
> not present). Nothing here talks to a real server, processes a real payment, or
> dispatches a real driver. Every such point is marked `INTEGRATION POINT` in the
> code. See [What is NOT done](#what-is-not-done).
>
> It has **not been compile-verified** — no Flutter SDK was available in the build
> environment. Run `flutter analyze` and `flutter test` locally before relying on
> it.

## Running

Prerequisites: Flutter `>=3.27`, Dart `>=3.6`.

```bash
# 1. Generate platform folders (android/ ios/ etc.) — not committed.
flutter create .

# 2. Fetch deps (also auto-generates localizations from lib/l10n/*.arb).
flutter pub get

# 3. Run against the mock backend (default — no backend required).
flutter run

# 4. Static analysis + tests
flutter analyze
flutter test
```

### Connecting the real backend (later)

The entire mock/real switch lives in **`lib/app/di.dart`** plus one flag:

```bash
flutter run \
  --dart-define=WESAL_USE_MOCKS=false \
  --dart-define=WESAL_FLAVOR=staging \
  --dart-define=WESAL_API_BASE_URL=https://api.staging.wesal.sa \
  --dart-define=WESAL_WS_BASE_URL=wss://realtime.staging.wesal.sa
```

To connect it for real you implement the domain contracts (below) as
`Real*Repository` classes and return them from the providers in `di.dart` when
`!useMockServices`. **No screen or controller changes** — they depend only on the
interfaces.

## Architecture

```
lib/
  app/          # entry, theme app, router, DI (mock/real switch), locale
  core/         # config, Result/Failure types, secure token store, logger, ui helpers
  design_system/# tokens (colors/type/spacing) + reusable components + map abstraction
  l10n/         # app_en.arb, app_ar.arb (generated/ is git-ignored, built on pub get)
  features/
    auth/       # splash, onboarding, phone+OTP, profile setup  (contract + mock + UI)
    trips/      # domain models, trip state machine, booking + active-trip + history UI
    payments/   # payment-method model, contract, mock, UI
    realtime/   # realtime contract (+ mock); real impl is a WebSocket client later
    safety/     # safety center sheet
    legal/      # terms/privacy (content loads from backend later)
    account/    # account, language switch, logout
    mock/       # ⚠️ the in-memory mock backend + mock repositories (not shipped to prod)
```

**Design principles honored**

- **Backend is authoritative.** The client never computes fares (§9), never picks
  the driver (§12), and never invents trip state — the state machine in
  `features/trips/domain/trip_status.dart` is the single mapping from backend
  wire values (§30).
- **Swappable services.** Screens depend on interfaces
  (`AuthRepository`, `TripRepository`, `PaymentRepository`, `RealtimeService`),
  not implementations.
- **Security.** No secrets in the app; tokens via keychain/keystore
  (`SecureTokenStore`); a redaction-aware logger that never logs OTP/tokens/cards;
  payments are token-only. See §28/§40 notes in code.
- **Arabic-first + RTL.** `ar` and `en` ARB files; switching to Arabic flips the
  whole layout RTL automatically.
- **Recovery.** On launch the app asks the backend for the active trip and the
  realtime layer re-fetches authoritative state on reconnect (§31/§41).

## Domain contracts (what the backend must implement)

- `features/auth/domain/auth_repository.dart` — phone/OTP, token lifecycle.
- `features/trips/domain/trip_repository.dart` — place search, fare quote,
  request ride (idempotent), trip fetch, active trip, cancel, rate, history.
- `features/payments/domain/payment_repository.dart` — tokenized methods.
- `features/realtime/realtime_service.dart` — trip update stream + reconnect.

These are the de-facto API spec for the backend team until an OpenAPI/proto
contract exists.

## What is done (phase 1)

Splash · onboarding · phone login · OTP · profile setup · home (map + booking
card) · destination search · location confirm (route preview, distance/time) ·
ride selection + fare + payment selection · confirm ride (idempotent) · searching
for driver · driver assigned/arriving/arrived · live active trip · cancel ·
safety center · trip completed + rating · receipt · trips history · trip details ·
account · payment methods · language switch · terms/privacy placeholders · shared
loading/empty/error states · trip state machine · mock realtime driver movement.

## What is NOT done

Carried as `INTEGRATION POINT` markers / follow-ups:

- Real HTTP/WebSocket repositories (the whole `Real*` side of `di.dart`).
- Real maps SDK (keys live in native projects) — `WesalMap` is a styled stand-in.
- Real payments (Mada/Apple Pay tokenization via the approved provider).
- Push notifications (FCM/APNs), analytics, crash/observability wiring.
- Masked driver calling; emergency dialer (Saudi 911) launch.
- Versioned legal content loading; saved-places editor; full profile editing.
- Location-permission platform flows (the manual-pickup fallback path is stubbed).
- History pagination (hook present via `TripPage.nextCursor`).
- Widget/integration tests and the full end-to-end test matrix (§44).
- `flutter create .` platform folders and native build/signing config.
```
