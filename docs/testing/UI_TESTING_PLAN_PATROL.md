# DevFlutt — Advanced UI Testing Plan with Patrol (LeanCode)

**Milestone:** v0.6.0+ UI Testing Infrastructure  
**Framework:** Patrol by LeanCode (E2E UI Testing for Flutter)  
**Platform:** Android (emulator first, physical device second)  
**CI/CD:** GitHub Actions  
**Status:** Planning / Design

---

## 1. Executive Summary

This plan defines a production-grade UI testing system for DevFlutt using **Patrol by LeanCode** — a Flutter-native E2E UI testing framework that overcomes the limitations of `integration_test` by handling native OS interactions (permission dialogs, notifications, device settings, WebView, etc.).

### Goals

| Goal | Description |
|------|-------------|
| **E2E UI Coverage** | Test complete user flows on real Android emulators using Patrol |
| **Native Automation** | Test native interactions (permissions, app lifecycle, device settings) that `integration_test` cannot |
| **Agent-Friendly** | Test structure optimized for AI agents to write, run, and debug Patrol tests |
| **CI/CD Integration** | Patrol tests run in GitHub Actions on every PR and push |
| **Reporting** | Unified test reports, video recordings, failure screenshots, coverage |
| **Cross-Version Verification** | Run Patrol tests against generated projects from v0.1.0 through v0.5.0 |

### Non-Goals

- Unit testing business logic (already covered by `flutter test`)
- Widget testing (already covered, but Patrol finders may supplement)
- iOS testing (no macOS runner available — documented as deferred)
- Physical device farming (Firebase Test Lab/BrowserStack) — optional future extension

---

## 2. Current State Analysis (v0.1.0 → v0.5.0)

### Existing Test Infrastructure

```
test/
  unit/
    app_config_test.dart          # Unit tests for configuration
  widget/
    app_test.dart                 # Widget test: home screen rendering
    app_theme_test.dart           # Widget test: theme, dark mode, text scale
    home_page_test.dart           # Widget test: home page content + accessibility
```

**Coverage:**
- Unit tests: `AppEnvironment`, `AppConfig` — configuration parsing, env detection, feature flags
- Widget tests: `DevFluttApp`, `AppTheme`, `HomePage` — rendering, theming, accessibility

**Gaps:**
- ❌ No integration tests (`integration_test/` does not exist)
- ❌ No Patrol tests (`patrol_test/` does not exist)
- ❌ No E2E user flows (login, navigation, app lifecycle)
- ❌ No native automation (permissions, notifications, device settings)
- ❌ No CI for UI tests on emulators
- ❌ No video/screenshot reporting for UI tests

### Version Matrix to Verify

| Version | Milestone | UI Tests to Run | Notes |
|---------|-----------|-----------------|-------|
| v0.1.0 | Initial template | Patrol smoke tests | Blank template |
| v0.2.0 | HTTP client + error model | Patrol API flow tests | Network interactions |
| v0.3.0 | Logging + diagnostics adapters | Patrol logging flow tests | Log verification |
| v0.4.0 | CI pipeline + workflow hardening | Patrol CI smoke tests | CI integration |
| v0.5.0 | Authentication + backend adapters | Patrol auth flow tests | Login, session, token refresh |

---

## 3. Patrol Framework Setup

### 3.1 Dependencies

Add to `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  
  # Patrol E2E UI testing
  patrol: ^4.10.0          # Patrol framework
  patrol_finders: ^4.10.0  # Custom finders (optional, for widget tests)
  integration_test:
    sdk: flutter
```

Install Patrol CLI globally:

```bash
dart pub global activate patrol_cli
# Add to PATH: %USERPROFILE%\AppData\Local\Pub\Cache\bin (Windows)
```

Verify installation:

```bash
patrol doctor
```

### 3.2 `pubspec.yaml` Patrol Configuration

```yaml
patrol:
  app_name: DevFlutt
  test_directory: patrol_test
  android:
    package_name: com.example.devflutt
  ios:
    bundle_id: com.example.devflutt
  macos:
    bundle_id: com.example.devflutt
```

### 3.3 Android Native Setup

Patrol requires native Android setup. The project uses flavors (`dev`, `staging`, `prod`). We need to configure the Android test instrumentation.

**`android/app/build.gradle`** — add `clearPackageData: true` for test isolation:

```gradle
android {
    defaultConfig {
        testOptions {
            unitTests {
                includeAndroidResources = true
            }
        }
        // Patrol requires clearPackageData for test isolation
        testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"
    }
}
```

**`android/app/src/main/AndroidManifest.xml`** — add test permissions if needed.

### 3.4 Test Directory Structure

```
test/                          # Existing: unit + widget tests (flutter test)
  unit/
  widget/
patrol_test/                   # NEW: Patrol E2E tests (patrol test)
  common/                      # Shared helpers, app initialization
    app_helper.dart            # App initialization for Patrol tests
    test_data.dart             # Test fixtures and mock data
    matchers.dart              # Custom matchers and assertions
  pages/                       # Page Object Model classes
    home_page.dart
    login_page.dart
    settings_page.dart
  flows/                       # End-to-end user flow tests
    app_lifecycle_test.dart
    navigation_test.dart
    auth_flow_test.dart
    theme_test.dart
  native/                      # Native automation tests
    permission_test.dart
    notification_test.dart
    device_settings_test.dart
  smoke/                       # Smoke tests for CI
    smoke_test.dart
```

### 3.5 `.gitignore` Additions

```
# Patrol artifacts
**/test_bundle.dart
.patrol.env
patrol_test/videos/
patrol_test/screenshots/
```

---

## 4. Test Architecture

### 4.1 Testing Pyramid

```
                    E2E (Patrol)          ← Small set, critical flows
                   /        \
             Integration     ← Native automation + app lifecycle
            /                  \
           /                    \
      Widget (flutter_test)     ← UI component behavior
     /                            \
   Unit (flutter_test)            ← Business logic, configuration
```

### 4.2 Layer Responsibilities

| Layer | Tool | Purpose | Examples |
|-------|------|---------|----------|
| Unit | `flutter test` | Pure Dart logic, no Flutter framework | `AppConfig`, `AppEnvironment` |
| Widget | `flutter_test` + Patrol finders | UI component rendering, interactions | `HomePage`, `AppTheme` |
| Integration | Patrol | Multi-screen flows, app lifecycle | Login → Dashboard → Logout |
| E2E | Patrol + Native | Native OS interactions | Permissions, notifications, dark mode |

### 4.3 Test Categories

```
patrol_test/
  smoke/              # Fast smoke tests (CI gate on every PR)
  flows/              # Critical user flows (login, navigation)
  native/             # Native automation (permissions, device settings)
  regression/         # Full regression suite (nightly)
  version_matrix/     # Tests across v0.1.0→v0.5.0 generated projects
```

### 4.4 Tags Strategy

```dart
patrol(
  'login flow',
  tags: ['smoke', 'auth', 'android'],
  ($) async { ... },
);

patrol(
  'permission dialog',
  tags: ['native', 'android', 'regression'],
  ($) async { ... },
);
```

CI runs:
- `patrol test --tags smoke` — on every PR
- `patrol test --exclude-tags regression` — on every push to main
- `patrol test` (all tags) — nightly

---

## 5. Page Object Model (POM)

### 5.1 Base Page Class

```dart
// patrol_test/pages/base_page.dart
import 'package:patrol/patrol.dart';

abstract class BasePage {
  final PatrolTester $;
  BasePage(this.$);

  Future<void> waitForPage() => throw UnimplementedError();
}
```

### 5.2 Home Page Object

```dart
// patrol_test/pages/home_page.dart
import 'package:patrol/patrol.dart';

class HomePage extends BasePage {
  HomePage(super.$);

  static const titleText = 'Home';
  static const descriptionText = 'Your app is ready';
  static const logoSemantics = 'Flutter logo';

  Future<void> waitForPage() => 
    $(titleText).waitUntilVisible();

  Future<void> verifyContent() {
    expect($(titleText), findsOneWidget);
    expect($(descriptionText), findsOneWidget);
    expect($(logoSemantics), findsOneWidget);
  }

  Future<void> verifyNoOverflow(double textScale) {
    // Already verified via MediaQuery in widget tests
    // Patrol can verify on real device
  }
}
```

### 5.3 Login Page Object (for auth flows)

```dart
// patrol_test/pages/login_page.dart
class LoginPage extends BasePage {
  LoginPage(super.$);

  static const emailField = Key('emailTextField');
  static const passwordField = Key('passwordTextField');
  static const loginButton = Key('loginButton');
  static const errorText = 'Invalid credentials';

  Future<void> waitForPage() => $(#emailTextField).waitUntilVisible();

  Future<void> enterCredentials(String email, String password) {
    await $(#emailTextField).enterText(email);
    await $(#passwordTextField).enterText(password);
  }

  Future<void> tapLogin() => $(#loginButton).tap();

  Future<void> verifyError() => $(errorText).waitUntilVisible();
}
```

---

## 6. App Initialization for Patrol

Patrol does NOT use `runApp()`. Instead, use `$.pumpWidgetAndSettle()`.

```dart
// patrol_test/common/app_helper.dart
import 'package:flutter/material.dart';
import 'package:patrol/patrol.dart';
import 'package:devflutt/app.dart';
import 'package:devflutt/core/config/app_config.dart';

Future<void> createApp(PatrolTester $, {AppConfig? config}) async {
  config ??= const AppConfig(
    appName: 'DevFlutt Test',
    environment: AppEnvironment.development,
  );
  
  await $.pumpWidgetAndSettle(DevFluttApp(config: config));
}
```

### Key Rules (from Patrol docs):
1. ✅ DO NOT call `WidgetsFlutterBinding.ensureInitialized()`
2. ✅ DO NOT use `runApp()` — use `$.pumpWidget()` / `$.pumpWidgetAndSettle()`
3. ✅ DO NOT modify `FlutterError.onError`

---

## 7. Advanced Test Patterns

### 7.1 Patrol Custom Finders

Patrol's custom finder system makes tests more readable:

```dart
// Before (flutter_test style)
await tester.tap(find.byKey(Key('loginButton')));

// After (Patrol style)
await $(#loginButton).tap();
await $('Welcome, Charlie!').waitUntilVisible();
```

### 7.2 Native Automation

Patrol can interact with the OS — this is its key differentiator:

```dart
// Grant location permission
await $.platform.mobile.selectFineLocation();
await $.platform.mobile.grantPermissionWhenInUse();

// Toggle dark mode
await $.platform.mobile.enableDarkMode();

// Open notifications
await $.platform.mobile.openNotifications();
await $.platform.mobile.tapOnNotificationByIndex(0);

// App lifecycle (home → back to app)
await $.platform.mobile.pressHome();
// ... verify state preserved ...
```

### 7.3 App Lifecycle Test

```dart
// patrol_test/flows/app_lifecycle_test.dart
import 'package:patrol/patrol.dart';
import '../common/app_helper.dart';

void main() {
  patrolTest(
    'app state preserved after backgrounding',
    tags: ['smoke', 'lifecycle', 'android'],
    ($) async {
      await createApp($);
      
      // Verify initial state
      await $('Home').waitUntilVisible();
      
      // Background the app
      await $.platform.mobile.pressHome();
      
      // Wait briefly
      await Future.delayed(const Duration(seconds: 2));
      
      // Bring app back to foreground
      await $.platform.mobile.openApp(); // or relaunch
      
      // Verify state preserved
      await $('Home').waitUntilVisible();
    },
  );
}
```

### 7.4 Permission Test

```dart
// patrol_test/native/permission_test.dart
import 'package:patrol/patrol.dart';
import '../common/app_helper.dart';

void main() {
  patrolTest(
    'location permission flow',
    tags: ['native', 'android', 'regression'],
    ($) async {
      await createApp($);
      
      // Trigger permission request (app-specific)
      await $(#requestLocationPermission).tap();
      
      // Handle native permission dialog
      await $.platform.mobile.selectFineLocation();
      await $.platform.mobile.grantPermissionWhenInUse();
      
      // Verify permission granted in app
      await $('Location permission granted').waitUntilVisible();
    },
  );
}
```

### 7.5 Auth Flow Test (v0.5.0)

```dart
// patrol_test/flows/auth_flow_test.dart
import 'package:patrol/patrol.dart';
import '../common/app_helper.dart';
import '../pages/login_page.dart';
import '../pages/home_page.dart';

void main() {
  group('Auth Flow', () {
    late LoginPage loginPage;
    late HomePage homePage;

    setUpAll(() {
      loginPage = LoginPage($);
      homePage = HomePage($);
    });

    patrolTest(
      'successful login navigates to home',
      tags: ['smoke', 'auth', 'android'],
      ($) async {
        await createApp($);
        
        await loginPage.waitForPage();
        await loginPage.enterCredentials('test@example.com', 'password123');
        await loginPage.tapLogin();
        
        await homePage.waitForPage();
        await homePage.verifyContent();
      },
    );

    patrolTest(
      'invalid credentials show error',
      tags: ['auth', 'android'],
      ($) async {
        await createApp($);
        
        await loginPage.waitForPage();
        await loginPage.enterCredentials('bad@example.com', 'wrong');
        await loginPage.tapLogin();
        
        await loginPage.verifyError();
      },
    );
  });
}
```

---

## 8. Emulator Management

### 8.1 Local Emulator Setup

Since the user has Flutter emulators available:

```bash
# List available emulators
flutter emulators

# Create a new emulator (if needed)
flutter emulators --create --name devflutt_test

# Start an emulator
flutter emulators --launch devflutt_test

# Run Patrol test on specific emulator
patrol test --device <emulator-serial>
```

### 8.2 CI Emulator Strategy

For GitHub Actions, use `emulator.wtf` or Firebase Test Lab:

```yaml
# .github/workflows/patrol-ui-tests.yml
- name: Install ew-cli (emulator.wtf)
  run: |
    mkdir -p "$HOME/bin"
    curl "https://maven.emulator.wtf/releases/ew-cli" -o "$HOME/bin/ew-cli"
    chmod a+x "$HOME/bin/ew-cli"
    echo "$HOME/bin" >> $GITHUB_PATH

- name: Patrol build android
  run: patrol build android --tags='android'

- name: Run Patrol tests on emulator.wtf
  run: |
    ew-cli emulatorwtf.yaml:multi_api \
      --device model=Pixel7,version=34 \
      --display-name "DevFlutt Patrol API ${{ matrix.api-level }}"
```

### 8.3 Device Matrix

| Device | API Level | Use Case |
|--------|-----------|----------|
| Pixel 7 | 34 (Android 14) | Primary test device |
| Pixel 6 | 33 (Android 13) | Compatibility |
| Pixel 5 | 31 (Android 12) | Older API support |

---

## 9. CI/CD Integration

### 9.1 New GitHub Actions Workflow

Create `.github/workflows/patrol-ui-tests.yml`:

```yaml
name: Patrol UI Tests

on:
  push:
    branches: [main]
  pull_request:

permissions:
  contents: read

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  patrol-smoke:
    name: Patrol Smoke Tests
    runs-on: ubuntu-latest
    timeout-minutes: 30
    steps:
      - name: Checkout
        uses: actions/checkout@v7

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable
          flutter-version: 3.47.7
          cache: true

      - name: Resolve dependencies
        run: flutter pub get

      - name: Install Patrol CLI
        run: dart pub global activate patrol_cli
        env:
          PATH: "$PATH:$HOME/.pub-cache/bin"

      - name: Verify Patrol setup
        run: patrol doctor

      - name: Run Patrol smoke tests
        run: |
          export PATH="$PATH:$HOME/.pub-cache/bin"
          patrol test --tags smoke --device <emulator>

      - name: Upload test artifacts
        if: always()
        uses: actions/upload-artifact@v7
        with:
          name: patrol-reports
          path: |
            patrol_test/videos/
            patrol_test/screenshots/
          if-no-files-found: ignore
```

### 9.2 CI Job Dependencies

The Patrol UI test job depends on:
- `quality` job passing (format, analyze, unit/widget tests)
- `generated-projects` job passing (all presets build and test)

---

## 10. Reporting and Monitoring

### 10.1 Patrol Reports

Patrol generates:
- Test summary (pass/fail/skip counts)
- Duration per test
- Test report path

### 10.2 Video Recording

```bash
patrol test --record-video --video-output-dir patrol_test/videos
```

Videos saved as `.mp4` in `patrol_test/videos/`.

### 10.3 Failure Screenshots

```yaml
# pubspec.yaml
patrol:
  screenshot_on_failure: true
```

Or programmatically:
```dart
await $.takeNativeScreenshot('login_failure');
```

### 10.4 Coverage

```bash
patrol test --coverage
```

Generates LCOV report at `coverage/patrol_lcov.info`.

### 10.5 Unified Report Template

```
┌─────────────────────────────────────────────────────────┐
│ DevFlutt UI Test Report                                 │
├─────────────────────────────────────────────────────────┤
│ Version: v0.5.0                                         │
│ Commit: b70a049                                         │
│ Run ID: 39800363669                                     │
│                                                         │
│ Total: 24                                               │
│ ✅ Passed: 22                                           │
│ ❌ Failed: 2                                            │
│ ⏩ Skipped: 0                                           │
│ Duration: 4m 32s                                        │
│                                                         │
│ Failures:                                               │
│   - login flow > invalid credentials (auth)             │
│   - permission dialog (native)                          │
│                                                         │
│ Artifacts:                                              │
│   - Videos: patrol_test/videos/                         │
│   - Screenshots: patrol_test/screenshots/               │
│   - Coverage: coverage/patrol_lcov.info                 │
└─────────────────────────────────────────────────────────┘
```

---

## 11. Version Matrix Testing (v0.1.0 → v0.5.0)

For each version tag, generate the project and run Patrol smoke tests:

```bash
#!/bin/bash
# scripts/run_version_matrix.sh

VERSIONS=("v0.1.0" "v0.2.0" "v0.3.0" "v0.4.0" "v0.5.0")

for version in "${VERSIONS[@]}"; do
  echo "=== Testing $version ==="
  
  git checkout $version
  flutter pub get
  
  # Generate projects for each preset
  for preset in blank core demo recommended; do
    dart run tool/ftemplate_cli/bin/ftemplate.dart create \
      --name "Test App" \
      --org com.example \
      --preset $preset \
      --output /tmp/patrol-matrix/$version-$preset \
      --force
    
    cd /tmp/patrol-matrix/$version-$preset
    flutter pub get
    
    # Run Patrol smoke tests
    patrol test --tags smoke --device <emulator>
    
    cd -
  done
done
```

Results are recorded in a matrix table similar to the existing CI matrix.

---

## 12. Test Data Management

### 12.1 Test Fixtures

```dart
// patrol_test/common/test_data.dart
class TestUsers {
  static const valid = User('test@example.com', 'password123');
  static const invalid = User('bad@example.com', 'wrong');
  static const locked = User('locked@example.com', 'password123');
}

class TestData {
  static const homeTitle = 'Home';
  static const homeDescription = 'Your app is ready';
}
```

### 12.2 Test Isolation

- **Android:** Set `clearPackageData: true` in `build.gradle`
- **Each Patrol test:** Starts with a fresh app instance
- **Shared state:** Use `setUp` / `tearDown` to reset between tests

---

## 13. Agent-Friendly Design

Since this project uses opencode/agents, the testing system must be agent-friendly:

### 13.1 Test Discovery

```bash
# List all Patrol tests
patrol test --list-tests

# Run tests matching a pattern
patrol test --targets patrol_test/flows/auth_flow_test.dart
```

### 13.2 Debug Mode (Hot Restart)

```bash
patrol develop --target patrol_test/flows/auth_flow_test.dart
```

Allows agents to:
- Make code changes
- Press `r` in terminal to hot restart
- See test results immediately

### 13.3 VS Code Extension

Install the Patrol VS Code Extension for:
- Inline test running
- Test debugging
- Visual test results

### 13.4 MCP Server

Patrol MCP enables agents to run tests programmatically:

```json
{
  "mcpServers": {
    "patrol": {
      "command": "dart",
      "args": ["run", "patrol_mcp"],
      "env": {
        "PROJECT_ROOT": ".",
        "PATROL_FLAGS": "",
        "SHOW_TERMINAL": "false"
      }
    }
  }
}
```

---

## 14. Implementation Timeline

### Phase 1: Foundation (Week 1)
- [ ] Add `patrol` and `patrol_finders` to `pubspec.yaml`
- [ ] Install `patrol_cli` globally
- [ ] Configure Android native setup
- [ ] Create `patrol_test/` directory structure
- [ ] Write smoke test for basic app launch

### Phase 2: Core Tests (Week 2)
- [ ] Create Page Object Models (HomePage, LoginPage)
- [ ] Write app lifecycle tests
- [ ] Write navigation tests
- [ ] Write theme/dark mode tests

### Phase 3: Native Automation (Week 3)
- [ ] Write permission dialog tests
- [ ] Write notification tests
- [ ] Write device settings tests

### Phase 4: CI Integration (Week 4)
- [ ] Create GitHub Actions workflow for Patrol
- [ ] Integrate with existing CI matrix
- [ ] Add video/screenshot reporting
- [ ] Add coverage collection

### Phase 5: Version Matrix (Week 5)
- [ ] Create version matrix test script
- [ ] Run Patrol tests against v0.1.0→v0.5.0
- [ ] Document results per version

---

## 15. Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Emulator flakiness | High | Use `--full-isolation`, retry failed tests once |
| Native dialog timing | Medium | Use `waitUntilVisible()` with timeouts |
| CI emulator startup slow | High | Cache emulator images, use emulator.wtf |
| iOS not supported | Low | Document as deferred (no macOS runner) |
| Patrol version drift | Medium | Pin Patrol version in pubspec, test upgrades |

---

## 16. Success Criteria

- [ ] Patrol CLI installs and `patrol doctor` passes
- [ ] Smoke tests run on Android emulator in < 2 minutes
- [ ] All critical user flows have Patrol E2E tests
- [ ] Native automation tests pass (permissions, lifecycle)
- [ ] CI runs Patrol tests on every PR and push
- [ ] Test reports, videos, and screenshots are captured
- [ ] Version matrix v0.1.0→v0.5.0 verified with Patrol tests
- [ ] Agent can write and run Patrol tests using `patrol develop`

---

## 17. References

- Patrol Documentation: https://patrol.leancode.co/documentation
- Patrol GitHub: https://github.com/leancodepl/patrol
- Patrol CLI on pub.dev: https://pub.dev/packages/patrol_cli
- Patrol package on pub.dev: https://pub.dev/packages/patrol
- Patrol VS Code Extension: https://patrol.leancode.co/blog/patrol-vs-code-extension
- Flutter CI with GitHub Actions: https://innersource.flutter.com/docs/actions

---

*Plan authored for DevFlutt v0.6.0+ UI Testing Infrastructure*  
*Framework: Patrol by LeanCode v4.10.0+*  
*Platform: Android Emulator (primary), Web (secondary)*  
*CI: GitHub Actions*