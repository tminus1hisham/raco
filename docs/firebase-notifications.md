# Firebase push notifications

The permissions page requests OS permission and registers the FCM token before
enabling an alert through the Communications API. Disabling an alert requires
only the Communications API and works even if OS permission is denied.

The app registers refreshed tokens using GET `/auth/get/account`, followed by
PUT `/auth/update/user` with the original account and changed `firebaseToken`.
This is the full-user update documented in api.md; verify that it is authorized
for every supported user role. A dedicated token-only endpoint would avoid
concurrent account edits being overwritten by this full-object API.

## Project configuration required

- Add the Firebase Android app configuration to `android/app/google-services.json`
  for package `com.mobile.orca`. The Google Services plugin is applied when this
  file exists.
- Add `GoogleService-Info.plist` to the iOS Runner target in Xcode, using Firebase
  app bundle ID `com.mobileApp.atom`. Enable the Push Notifications capability
  with the correct signing team/provisioning profile. Remote notification
  background mode is already declared.
- Upload the Apple APNs authentication key in Firebase Cloud Messaging settings.
- Use the same Firebase project as the server's FCM sender.

Missing configuration does not prevent the app from opening; attempts to enable
push alerts show a configuration error and restore the toggle.

## Delivery contract and verification

The backend must check the user's five Communications settings before sending
FCM messages to their `firebaseToken`. Send a `notification` payload with title
and body. Background/terminated notifications are displayed by the Firebase SDK
and OS. Foreground messages show an in-app banner and refresh the alert inbox.
Taps open the inbox after the authenticated dashboard is ready. Data-only
messages do not create a visible notification.

On a configured physical device, verify permission granted/denied, toggle save
failures, each alert category, foreground/background/terminated delivery,
notification taps, token refresh, and logout. No live delivery test has been
performed without Firebase project configuration and a backend sender.

References: https://firebase.google.com/docs/cloud-messaging/flutter/get-started
and https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages
