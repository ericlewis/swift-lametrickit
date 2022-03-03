# LaMetricKit

Swift library for interacting with [LaMetric TIME](https://lametric.com/en-US) devices on the local network. You will need a [developer account](https://developer.lametric.com/).

__Note: macOS doesn't support the static image icon API yet.__

### Features
- Simple: one config and one function.
- Concurrency first, even on older OS versions.
- A SwiftUI-like result builder interface for creating notifications.
- Expressive notification creation API even without using the result builders.
- Great documentation (WIP lol)

## Installation
- Using [Swift Package Manager](https://swift.org/package-manager)
```swift
import PackageDescription

let package = Package(
  name: "MyAwesomeApp",
  dependencies: [
    .package(url: "https://github.com/ericlewis/swift-lametrickit", from: "0.2.0"),
  ]
)
```

## Authentication
1. Create a [LaMetric developer account](https://developer.lametric.com/) if needed.
2. Get your devices API key from [here](https://developer.lametric.com/user/devices).
3. Find the local ip address of your device. 

### Configuration
Initialize a new `LaMetricKit.Configuration` as follows:
```swift
let config = LaMetricKit.Configuration(
  "8adaa0c98278dbb1ecb218d1c3e11f9312317ba474ab3361f80c0bd4f13a6749",
  ipAddress: "192.168.1.101"
)
```

After creating your configuration you can use it with `LaMetricKit`:
```swift
let notification = Notification {
  Simple("Hello World!")
}

try await LaMetricKit(config).push(notification) // Watch your LaMetric!
```

### Creating Notifications
Notfications are the high-level object we send to the device, it consists of a few properties 
and a collection of frames. Frames are the primary means of controlling the visual interface.
Sounds and other settings are applied at the notification level.

#### There are two ways of creating notifications, the first way:
```swift
Notification {
  Simple("Hello World!")
  Simple("How are you?") // multiple frames are this easy!
}
```
#### The second way:
```swift
Notification(frames: [.simple(text: "Hello World!")])
```
#### There are also a few variations of frames:
```swift
Notification {
  Simple("Hello!")
  Chart([1, 2, 3, 4])
  Progress(10, in: 0...100)
}
```
#### You can use conditionals too:
```swift
let morning = true

Notification {
  if morning {
    Simple("Good Morning!")
  } else {
    Simple("Where did the morning go?!")
  }
}
```
#### Use `UIImage`s as icons
```swift
Notification {
  Simple("Hello World!", icon: .staticImage(UIImage(named: "HandWave")!))
}
```
## License
MIT License, Copyright 2022 Eric Lewis.
