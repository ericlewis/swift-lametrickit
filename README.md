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
    .package(url: "https://github.com/ericlewis/swift-lametrickit", from: "0.1.0"),
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

## License
MIT License, Copyright 2022 Eric Lewis.
