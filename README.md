# Around

Around is an iOS app that notifies users to look around when the app detects the user is walking and using their phone at the same time for a prolonged period (currently set to 5 seconds). Around is written in Swift and utlizes the CoreLocation framework to fetch user's location updates to check if the user is inside their home building and uses CoreMotion framework to detect if the user is walking. This app was inspired by Google's [Digitial Wellbeing](https://wellbeing.google/) feature called Heads Up - please visit their website to learn about an Android alternative.

## Features

- [x] Only send notifications when the user is located outside their home building.
- [x] Allow app to run in background (requires user authorization).
- [x] Make home buliding annotation step optional, i.e., the app will start notifying users irrespective of user's location. This is however still require user authoirzation to fetch the location updates in background (so that the app can run in background).
- [x] Save user annotated building and user selections in `NSUserDefaults`.
- [ ] Add a search option inside `HomeMapView` for a faster way to annotate the home building.
- [ ] Add interactive local notification to look around with options to disable notifications for 30 minutes or 1 hour.
- [ ] Add more than one (home) building, so that the app doesn't send notification when the user is located inside those buildings (currently supports only one building).  
- [ ] Allow user to customize the time they'd like the app to notify when it detects the user has been walking while using their phone.
