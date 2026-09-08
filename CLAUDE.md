# CLAUDE CODE EXTENSIONS TO MCP-BASED CONSTITUTION

**Precedence**: Constitutional principles (CL1–CL9, QS1–QS6, M1–M5) are foundational  
**Base Constitution**: See `AGENTS.md` — all constitutional laws, quality standards, macros, and enforcement levels apply  
**Additions**: Claude Code-specific behaviors and tool integrations

---

## Project Context

- **Project**: myfriendroze Flutter Admin App — internal tool for managing products and events for the myfriendroze ceramics & d.d. succulents Astro website
- **Tech stack**: Flutter / Dart / Firebase Auth (email/password) / Firestore / Firebase Storage
- **Primary language**: Dart
- **Non-goals**: Not a customer-facing app. No iOS production target (web + Android only). No complex state management libraries beyond Provider. No offline-first features.
- **Key files**:
  - `myfriendroze-app/lib/main.dart` — app entry point, Firebase init, routing
  - `myfriendroze-app/lib/screens/` — UI screens (auth, home, products, events, profile)
  - `myfriendroze-app/lib/services/firestore_service.dart` — Firestore CRUD operations
  - `myfriendroze-app/lib/services/storage_service.dart` — Firebase Storage image upload
  - `myfriendroze-app/lib/models/` — product.dart, event.dart data models
  - `myfriendroze-app/lib/providers/` — auth_provider.dart, product_provider.dart, event_provider.dart
  - `myfriendroze-app/lib/firebase_options.dart` — Firebase project config (project: myfriendroze-platform)
  - `myfriendroze-app/pubspec.yaml` — Flutter dependencies

---

## Platform (Windows 11)

This project runs on **Windows 11** with Flutter SDK installed. Rules:

- **Flutter project root**: `myfriendroze-app/` (one level below the repo root — `pubspec.yaml` lives at `myfriendroze-app/pubspec.yaml`) — always run `flutter` commands from here
- **Web dev**: `flutter run -d chrome` (opens Chrome in debug mode)
- **Android**: `flutter run -d android` or `flutter run -d <device-id>`
- **Analyze**: `flutter analyze` (equivalent to type-checking)
- **Test**: `flutter test`
- **Build web**: `flutter build web`
- **Dart paths**: use forward slashes in import statements (`package:myfriendroze_admin/...`)

---

## Terminal Command Discipline (MANDATORY)

Before running **any** terminal command, state:
1. **WHY** — what question it answers or what state it changes
2. **WHAT** — the command does, step by step

"I'll just check..." is not sufficient. No exceptions.

---

## Commit Format

Every commit message must include:

```
Concise summary (≤72 chars)

WHY:
- Rationale for the change

EXPECTED:
- Observable outcome (test names, behaviors satisfied)
```

No tool attribution in commit messages.

---

## Git Workflow (MANDATORY)

- **Never commit directly to `main`** for feature work.
- **Every feature, fix, or improvement** gets its own branch: `feature/name`, `fix/name`, `chore/name`.
- **Never run `git commit` without explicit permission** from Emily in the current conversation.
- Trivial one-line config changes may be committed to main only with explicit approval.
- **Merge via GitHub, not locally**: after pushing a branch, open a PR (`gh pr create`) and merge it with `gh pr merge` or the GitHub UI — never `git merge` locally followed by a direct push to `main`. A local merge+push is invisible on GitHub (just an anonymous commit landing on `main`, no PR history, no inline checks-passed summary). Going through a real PR is also what's required for a future branch-protection rule to actually mean anything.

---

## Project Architecture

```
myfriendroze-app/
├── myfriendroze-app/           ← Flutter project root
│   ├── lib/
│   │   ├── main.dart           ← Entry point
│   │   ├── firebase_options.dart
│   │   ├── models/             ← Product, Event (data classes, fromMap/toMap)
│   │   ├── providers/          ← AuthProvider, ProductProvider, EventProvider
│   │   ├── screens/
│   │   │   ├── auth/           ← Login, Register screens
│   │   │   ├── home/           ← Dashboard
│   │   │   ├── products/       ← Product list, add/edit product
│   │   │   ├── events/         ← Event list, add/edit event
│   │   │   └── profile/        ← User profile
│   │   ├── services/           ← FirestoreService, StorageService
│   │   ├── theme/              ← App theming
│   │   ├── routes/             ← App routing
│   │   ├── utils/              ← Utilities
│   │   └── widgets/            ← Reusable widgets
│   ├── test/                   ← Flutter tests
│   ├── pubspec.yaml
│   └── pubspec.lock
└── docs/                       ← Architecture docs (gitignored for working notes)
```

**Key conventions**:
- Models use `fromMap(Map<String, dynamic>)` and `toMap()` for Firestore serialization
- All Firestore operations go through `FirestoreService` — no direct Firebase calls in UI
- All Storage operations go through `StorageService`
- Auth state is managed by `AuthProvider` — screens use `context.watch<AuthProvider>()`
- Firebase project: `myfriendroze-platform` — data written here is read by the Astro website

---

## Constitutional Laws (Binding — Summary)

See `AGENTS.md` for full text. Key reminders:

- **CL1 INSTRUCTION PRIMACY**: CLAUDE.md + AGENTS.md are law. Deviation = constitutional violation.
- **CL3 NO SHORTCUTS**: Never stub or simplify to get unstuck. Admit stuckness and ask Emily.
- If the best approach is unclear or you are unsure, ask Emily before proceeding.
- **CL4 SELF-MONITORING**: Before every action, ask:
  - Am I bypassing `FirestoreService` / `StorageService` and calling Firebase directly from a widget?
  - Am I putting business logic in a screen widget instead of a provider or service?
  - Am I about to introduce a security issue (exposing admin credentials, no auth guard on a route)?
- **CL6 TDD ENFORCEMENT**: RED → GREEN → COMMIT → REFACTOR. Tests first. Always.
- **CL7 NO TIME PRESSURE**: "Due to constraints" is never a valid justification.
- **CL9 SECURITY**: This app manages admin access to product and event data. All screens must check authentication state. Never store credentials in plaintext. Firebase Auth handles session management — don't bypass it.

---

## Quality Standards (Binding — Summary)

- **QS1 TDD/BDD**: >85% coverage on services and providers. Theater test check mandatory. Widget tests for critical screens (login, product form).
- **QS4 FILES**: ≤500 LOC per file. Large screens should be decomposed into smaller widgets.
- **QS5 DATA ISOLATION**: Tests use mock Firestore (fake Firebase) or mock service implementations. Never connect to the production `myfriendroze-platform` project in tests.

---

## File Organization

**Root** (`myfriendroze-app/`): `README.md`, `CLAUDE.md`, `AGENTS.md`, `docs/` only.  
**Flutter project root** (`myfriendroze-app/`, one level below the repo root): `pubspec.yaml`, `lib/`, `test/`, `android/`, `web/`, `windows/`.  
**Working notes / analysis**: `docs/` folder (gitignore it).  
**Never** create documentation files in either root unless user-facing.

---

## Claude Code Internal Tools

**Skills** — invoked via Skill tool. Only use skills listed in the tool's available commands.

**Sub-agents** — spawned via Task tool. Use for:
- Codebase exploration (open-ended, not needle-in-haystack)
- Multi-step autonomous work requiring specialization
- Adversarial TDD (test-writer / coder separation)

---

## TDD Skill Integration

Use `/test-driven-development` skill for RED→GREEN→COMMIT→REFACTOR cycle.

**Applies primarily to**:
- `lib/services/` — FirestoreService, StorageService (all CRUD logic)
- `lib/providers/` — AuthProvider, ProductProvider, EventProvider (state logic)
- `lib/models/` — fromMap/toMap serialization logic

**Widget/screen files** are UI-only. Extract logic into providers/services and test those. Use Flutter widget tests (`testWidgets`) for critical user flows (login success/failure, form validation).

---

## Deployment

**Master auto-deploys the web build.** Merging a PR to `master` automatically builds and deploys the web/PWA build to Firebase Hosting via GitHub Actions (the `deploy` job in `.github/workflows/ci.yml`) — no manual step needed. It runs the same `scripts/deploy-web.sh` used for local manual deploys, so the build-number convention below applies identically either way. Android has no CD (no native build is currently distributed, see admin-app-web-hosting memory) — `flutter build apk` stays manual.

```bash
# Run in browser (dev) — from the repo root, the Flutter project is one
# level down (pubspec.yaml lives at myfriendroze-app/pubspec.yaml)
cd myfriendroze-app
flutter run -d chrome

# Manual web deploy — e.g. to verify a fix before merging, or to redeploy
# without a new commit. Use the script, not raw flutter/firebase commands:
# it bakes in --build-number=$(git rev-list --count HEAD) so the Profile
# screen's version display actually changes on every real deploy (see
# lib/screens/profile/profile_screen.dart); typed by hand, that flag is
# easy to forget, which silently falls back to pubspec.yaml's static value
# and makes every build look identical. CD uses this same script.
./scripts/deploy-web.sh

# Build Android APK, same build-number convention (no deploy script or CD
# yet — no native Android build is currently distributed)
flutter build apk --build-number=$(git rev-list --count HEAD)

# Analyze for issues
flutter analyze

# Run tests
flutter test
```

Admin accounts must be created manually in the Firebase Console (Authentication → Add user).  
The app writes to `myfriendroze-platform` Firestore — changes are reflected in the Astro website at next build.

**Confirming a deploy actually shipped**: the Profile screen shows `Version <pubspec version> (<build number>)`. If the build number shown on a device/browser doesn't match `git rev-list --count HEAD` on the commit that should be live, that device is running a stale build — for web, check the CD run in GitHub Actions actually succeeded before assuming the fix is wrong; for Android (no CD), rebuild and reinstall the APK.
