# EduAccess iOS

A SwiftUI client for the [EduAccess](https://github.com/lakshya110704/EduAccess) Django REST backend. A student logs in, checks a professor's availability, requests an appointment and cancels it. A professor logs in, sets their availability and confirms or cancels requests.

It has been run against a local copy of the backend, over HTTP and over HTTPS. It is not on the App Store.

## Features

- Log in as a student or professor with the backend's session login (CSRF cookie plus form post), and log out
- List the student's saved professors, or search all professors, with status (Free, Busy, Unavailable), the professor's note, cabin and today's walk-in hours
- Save and remove professors, and open a professor's cabin directions on the web app
- Request a 15 or 30 minute appointment with a time, a reason and optional details. Times round up to the quarter hour, as the backend requires
- List appointments with their start and end times, and cancel one, with a confirmation first
- Students edit the reason for a request while it is pending
- Professors set their status with a note and a time they'll be back, and confirm or cancel requests. Confirming declines overlapping requests on the backend, and the list reloads to show that
- Professors add and remove walk-in time for today
- Professors set and change their cabin. Without one, they must set it before anything else, as on the website
- Availability and appointment lists refresh every 10 seconds while on screen, as the web app's dashboards do
- Notifications list for both roles, refreshed with the other lists
- Request an account from the login screen. It shows every field's errors, scrolls to the first one, and says the account waits for an admin to activate it. It does not log the user in
- Stay logged in between launches, with a welcome line showing the user's name
- Return to login with a message when the backend says the session has ended
- Show the backend's own error message when it refuses a request

## How it is built

- SwiftUI and Swift Concurrency, iOS 18.0 deployment target, no third-party dependencies
- MVVM: one `@Observable` view model per screen
- Views and view models depend on the `APIClient` protocol. `LiveAPIClient` talks to the backend with `URLSession`, and the tests use `MockAPIClient`
- The session cookie stays in the app's cookie storage, so a user stays logged in between launches, as on the website, until they log out or the backend ends the session

```
EduAccess/
  Models/         Professor, Appointment, Me, OpenTime, AppNotification, CampusBlock, Signup, UserRole, AvailabilityStatus
  Networking/     APIClient protocol, LiveAPIClient
  ViewModels/     Login, Signup, Professors, Booking, Appointments, ProfessorStatus, ProfessorGate, Cabin, OpenTime, Notifications
  Views/          SwiftUI screens
EduAccessTests/   View model tests with a mock, client tests, tests against a local backend
EduAccessUITests/ Full flows through the real app against a local backend
```

## Run it

Start the backend from a checkout of [lakshya110704/EduAccess](https://github.com/lakshya110704/EduAccess). The app expects it at `http://127.0.0.1:8000`.

```bash
uv venv --python 3.12 .venv
uv pip install --python .venv/bin/python -r requirements.txt --no-deps
export DB_ENGINE=sqlite DJANGO_DEBUG=True
.venv/bin/python manage.py migrate
.venv/bin/python manage.py seed_demo
.venv/bin/python manage.py runserver 127.0.0.1:8000
```

`seed_demo` creates demo students and professors. Its password is in `api/management/commands/seed_demo.py` in the backend. Sign-up and setting a cabin need backend commit `b9a5f97` or later, which is not on GitHub yet. To add the campus blocks and cabin-less professors they need, run this from the backend checkout:

```bash
.venv/bin/python manage.py shell < path/to/EduAccess-iOS/scripts/local_test_fixtures.py
```

Then open `EduAccess.xcodeproj` in Xcode and run the `EduAccess` scheme on an iOS 18 simulator. `seed_demo` creates accounts for both roles: `student1`, `student2`, `prof1` and `prof2`. A new student has no saved professors, so search for one (for example `AB2` or `gupta`) and tap its star.

To use another backend, set the `API_BASE_URL` build setting in Xcode, or pass it on the command line:

```bash
xcodebuild build -project EduAccess.xcodeproj -scheme EduAccess -destination 'generic/platform=iOS Simulator' API_BASE_URL=https://your-host.example CODE_SIGNING_ALLOWED=NO
```

## Tests

```bash
xcodebuild test -project EduAccess.xcodeproj -scheme EduAccess -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0' CODE_SIGNING_ALLOWED=NO
```

With the seeded backend running, supply its demo password to also run the tests that use it. They refuse any host but `127.0.0.1`, so they cannot write to a deployed backend.

```bash
TEST_RUNNER_EDUACCESS_TEST_PASSWORD=<seed_demo password> xcodebuild test -project EduAccess.xcodeproj -scheme EduAccess -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0' CODE_SIGNING_ALLOWED=NO
```

Last runs, on an iPhone 16 simulator with iOS 18.0 and Xcode 27.2:

| Run | Passed | Failed | Skipped |
|---|---|---|---|
| Fresh clone, no password | 107 | 0 | 21 |
| Local backend `b9a5f97` over HTTP | 128 | 0 | 0 |
| Local backend `b9a5f97` in production mode behind a local TLS proxy, over HTTPS | 128 | 0 | 0 |

The 21 skipped tests are the 17 that call the local backend directly and the 4 UI flows. The UI flows cover:

- A student searching, saving a professor, requesting an appointment and editing its reason, then a professor setting a status note, confirming and cancelling that request, and reading the notification about it
- A professor with no cabin being stopped until they set one
- Signing up with bad fields and seeing every error, then signing up properly, seeing the wait for approval, and being refused at login
- Logging in under the wrong role

These UI flows needed retries for dropped taps while the machine was under heavy load. Those retries are in the test code.

The sign-up flow is not fully stable. Run three times in a row, it passed twice, and the third run failed when the app crashed inside `XCTAutomationSupport`, Xcode's test support library, while it was logging an accessibility query. Before the app scrolled to the first error, the flow also failed once waiting for an error message, on a heavily loaded machine. That cause was not confirmed.

## Checked directly

Against the same local backend:

- A wrong password, or an account used under the wrong role, shows an error in the app
- Over HTTP, the app stayed logged in after being quit and reopened, and stayed logged out after logging out, quitting and reopening
- With sessions deleted on the backend while the app was open, the next refresh got `403` and the app returned to login with a message
- With the app left open, the backend log showed a request every 10 to 11 seconds for the visible tab only, and none after logout
- Over HTTPS with production settings, session and CSRF cookies were `Secure`. Writes without a `Referer` got `403` and writes with one succeeded
- Cabin directions page: `200` with `curl`
- The four sign-up and cabin endpoints on `b9a5f97`, with `curl` over HTTP and HTTPS: sign-up creates an inactive account, bad input returns every field's error, the cabin gate returns `403` until a cabin is set and then lifts, and students are refused. Backend `8be6939` returned `404` for all four

Deployed backend: only a read-only check that `/healthz/` returns `200` with a valid certificate. Logging in and any writes there are not yet run.

Not yet run: a physical device, iPad, dark mode, VoiceOver, pull to refresh, tapping the directions link, the app with the backend offline, and the app against a backend without the sign-up and cabin endpoints.

## Limitations

- **Sign-up and setting a cabin need a backend version that is not deployed yet.** They use `/api/signup/`, `/api/signup/options/`, `/api/campus-blocks/` and `/api/me/cabin/`, tested only against a local copy of backend commit `b9a5f97`. Older backends return `404` for them. From reading the code, not from running it, both features then fail, and a professor with no cabin can't get past the cabin screen in the app until the backend is updated. Until then this app does not have full parity with the deployed website
- Plain HTTP only works for local addresses. Anything else needs HTTPS
- The backend has no JSON login endpoint, so the app posts its HTML login form. That form's wrong-role and awaiting-approval messages are only in its HTML, so the app shows one shared message for both
- Cabin directions open the website's page, which has the Maps link, 360 view, written steps and WhatsApp share. The backend has no API for a native screen

## Roadmap

Nothing in this section is built:

- Push notifications. The in-app list is what the website has. Push would need a paid Apple Developer account and backend work

## Contributors

- Lakshya Mehta
- Mohini

## License

MIT. See [LICENSE](LICENSE).
