# EduAccess iOS

A small SwiftUI client for the [EduAccess](https://github.com/lakshya110704/EduAccess) Django REST backend. A student logs in, checks a professor's availability, requests an appointment and cancels it. A professor logs in, sets their availability and confirms or cancels requests.

It talks to a backend running locally and is not on the App Store.

## Features

- Log in as a student or professor with the backend's session login (CSRF cookie plus form post), and log out
- List the student's saved professors, or search all professors, with status (Free, Busy, Unavailable), the professor's note, cabin and today's walk-in hours
- Save and remove professors, and open a professor's cabin directions on the web app
- Request a 15 or 30 minute appointment with a time, a reason and optional details. Times round up to the quarter hour, as the backend requires
- List appointments and cancel one, with a confirmation first
- Professors set their status with a note and a time they'll be back, and confirm or cancel requests. Confirming declines overlapping requests on the backend, and the list reloads to show that
- Professors add and remove walk-in time for today
- Show the backend's own error message when it refuses a request

## How it is built

- SwiftUI and Swift Concurrency, iOS 18.0 deployment target, no third-party dependencies
- MVVM: one `@Observable` view model per screen
- Views and view models depend on the `APIClient` protocol. `LiveAPIClient` talks to the backend with `URLSession`, and the tests use `MockAPIClient`
- The session cookie is kept in an ephemeral `URLSession`, so nothing is stored on disk and each launch starts at login

```
EduAccess/
  Models/       Professor, Appointment, AvailabilityStatus
  Networking/   APIClient protocol, LiveAPIClient
  ViewModels/   Login, Professors, Booking, Appointments
  Views/        SwiftUI screens
EduAccessTests/ View model tests and LiveAPIClient tests
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

`seed_demo` creates demo students and professors. Its password is in `api/management/commands/seed_demo.py` in the backend.

Then open `EduAccess.xcodeproj` in Xcode and run the `EduAccess` scheme on an iOS 18 simulator. A new student has no saved professors, so search for one (for example `AB2` or `gupta`) and tap its star.

## Tests

```bash
xcodebuild test -project EduAccess.xcodeproj -scheme EduAccess -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0' CODE_SIGNING_ALLOWED=NO
```

Last run: 26 tests, 26 passed, 0 failed, on an iPhone 16 simulator with iOS 18.0 and Xcode 27.2. All of them use mocks or saved JSON, so they do not need the backend.

## Checked by hand

Run once on the same simulator against a local copy of the backend with its seed data, confirmed in the backend's request log:

- Wrong password: `401`, and the app shows an error
- Correct password: `302`, and the app opens the professors screen
- Search: `200`, and the professor's status and cabin appear
- Request an appointment: `201`, and it appears as Pending
- Cancel it: `200`, and it shows as Cancelled, which the backend database also shows
- Log out: `302`, and the app returns to login

Not yet run: a physical device, iPad, dark mode, VoiceOver, pull to refresh, the app's behavior with the backend offline, logging in with a professor account, and any HTTPS or deployed backend.

## Limitations

- The backend address is a constant in `LiveAPIClient.swift`, and only plain HTTP to a local server is allowed. A deployed HTTPS backend would also need a `Referer` header, which Django requires for CSRF over HTTPS
- The backend has no JSON login endpoint, so the app posts its HTML login form
- No notifications, although the backend supports them
- Professors set their cabin on the web app, because the backend has no API for it. A professor without a cabin can log in, but the backend refuses any change until the cabin is set

## Roadmap

Nothing in this section is built. The goal is full parity with the EduAccess web app:

- Notifications and automatic availability refresh

## Contributors

- Lakshya Mehta
- Mohini

## License

MIT. See [LICENSE](LICENSE).
