import Foundation

// MARK: Encodables

/// Object representing a notification to push
public struct Notification: Encodable {
  /// Object that represents message structure and data.
  public var model: Model

  /// Priority of the message
  public var priority: Priority?

  /// Represents the nature of notification.
  public var iconType: IconType?

  /// The time notification lives in queue to be displayed in milliseconds. **Default lifetime is 2 minutes.**
  ///
  /// If notification stayed in queue for longer than lifetime milliseconds – it will not be displayed.
  ///
  public var lifetime: Int?

  public init(
    model: Notification.Model,
    priority: Notification.Priority? = nil,
    iconType: Notification.IconType? = nil,
    lifetime: Int? = nil
  ) {
    self.model = model
    self.priority = priority
    self.iconType = iconType
    self.lifetime = lifetime
  }

  public init(
    frames: [Notification.Model.Frame],
    sound: Notification.Model.Sound? = nil,
    cycles: Int? = nil,
    priority: Notification.Priority? = nil,
    iconType: Notification.IconType? = nil,
    lifetime: Int? = nil
  ) {
    self.model = .init(frames: frames, sound: sound, cycles: cycles)
    self.priority = priority
    self.iconType = iconType
    self.lifetime = lifetime
  }
}

extension Notification {
  /// Priority of the message
  public enum Priority: String, Encodable {
    /// This priority means that notification will be displayed on the same “level” as all other notifications on the device
    /// that come from apps (for example facebook app). This notification will not be shown when screensaver is active.
    /// By default message is sent with “info” priority.
    ///
    /// This level of notification should be used for notifications like news, weather, temperature, etc.
    ///
    case info

    /// Notifications with this priority will interrupt ones sent with lower priority (info). Should be used to
    /// notify the user about something important but not critical.
    ///
    /// For example, events like “someone is coming home” should use
    /// this priority when sending notifications from smart home.
    ///
    case warning

    /// The most important notifications. Interrupts notification with priority _info_ or _warning_ and is displayed
    /// even if screensaver is active. Use with care as these notifications can pop in the middle of the night.
    /// Must be used only for really important notifications like notifications from smoke detectors, water leak
    /// sensors, etc.
    ///
    /// Use it for events that require human interaction immediately.
    ///
    case critical
  }

  /// Represents the nature of notification.
  public enum IconType: String, Encodable {

    /// no notification icon will be shown.
    case none

    /// “i” icon will be displayed prior to the notification.
    ///
    /// Means that notification contains information, no need to take actions on it.
    ///
    case info

    /// “!!!” icon will be displayed prior to the notification.
    ///
    /// Use it when you want the user to pay attention to that notification as it
    /// indicates that something bad happened and user must take immediate action.
    ///
    case alert
  }
  
  public struct Model: Encodable {
    /// Array of objects describing the notification structure.
    public var frames: [Frame]

    /// The sound to play when a notification is display.
    public var sound: Sound?

    /// The number of times message should be displayed. If cycles is set to 0, notification will stay on the screen
    /// until user dismisses it manually or you can dismiss it via the API (TODO!).
    ///
    /// By default it is set to 1.
    ///
    public var cycles: Int?

    public init(
      frames: [Notification.Model.Frame],
      sound: Notification.Model.Sound? = nil,
      cycles: Int? = nil
    ) {
      self.frames = frames
      self.sound = sound
      self.cycles = cycles
    }
  }
}

extension Notification.Model {
  public enum Frame: Encodable {
    case simple(icon: Icon = .identified(0), text: String?)
    case goal(icon: Icon = .identified(0), start: Int, current: Int, end: Int, unit: String)
    case chart(points: [Int])

    enum CodingKeys: CodingKey {
      case icon
      case text
      case goalData
      case chartData
    }

    enum GoalDataKeys: CodingKey {
      case start
      case current
      case end
      case unit
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      switch self {
      case let .simple(icon, text):
        try container.encode(icon, forKey: .icon)
        try container.encode(text, forKey: .text)
      case let .goal(icon, start, current, end, unit):
        var goal = container.nestedContainer(
          keyedBy: GoalDataKeys.self,
          forKey: .goalData
        )
        try goal.encode(start, forKey: .start)
        try goal.encode(current, forKey: .current)
        try goal.encode(end, forKey: .end)
        try goal.encode(unit, forKey: .unit)
        try container.encode(icon, forKey: .icon)
      case let .chart(points):
        try container.encode(points, forKey: .chartData)
      }
    }
  }
}

extension Notification.Model.Frame {
  public enum Icon: Encodable {
    /// A provided UIImage which is automatically downscaled to fit.
    ///
    /// Note: you will get better results if you create images that are 8x8 pixels.
    ///
    #if canImport(UIKit)
    case staticImage(UIImage)
    #endif

    /// Use an icon provided by LaMetric
    ///
    /// Find a full list [here](https://developer.lametric.com/icons).
    ///
    case identified(Int, animated: Bool = false)

    public func encode(to encoder: Encoder) throws {
      var container = encoder.singleValueContainer()

      switch self {
      case let .identified(id, animated):
        try container.encode(animated ? "a\(id)" : "i\(id)")
      #if canImport(UIKit)
      case let .staticImage(uiImage):
        guard let data = uiImage.scaled().pngData() else {
          throw EncodingError.imageRescaleFailed
        }
        let base64 = data.base64EncodedString(options: .lineLength64Characters)
        let string = "data:image/png;base64,\(base64)"
        try container.encode(string)
      #endif
      }
    }
  }
}

extension Notification.Model.Frame.Icon {
  public enum EncodingError: Error {
    case imageRescaleFailed
  }
}

extension Notification.Model {
  public enum Sound: Encodable {
    /// Repeat count defines the number of times sound must be played.
    /// If set to 0 sound will be played until notification is dismissed.
    ///
    /// Default count is 1.
    ///
    case alarm(Alarm, repeatCount: Int = 1)

    /// Repeat count defines the number of times sound must be played.
    /// If set to 0 sound will be played until notification is dismissed.
    ///
    /// Default count is 1.
    ///
    case notice(Notice, repeatCount: Int = 1)

    enum CodingKeys: CodingKey {
      case category
      case id
      case `repeat`
    }

    enum Category: String, Codable {
      case alarms, notifications
    }

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      switch self {
      case let .alarm(sound, repeatCount):
        try container.encode(sound, forKey: .id)
        try container.encode(repeatCount, forKey: .repeat)
        try container.encode(Category.alarms, forKey: .category)
      case let .notice(sound, repeatCount):
        try container.encode(sound, forKey: .id)
        try container.encode(repeatCount, forKey: .repeat)
        try container.encode(Category.notifications, forKey: .category)
      }
    }
  }
}

extension Notification.Model.Sound {
  /// Notification sounds
  public enum Notice: String, Codable {
    case bicycle
    case car
    case cash
    case cat
    case dog
    case dog2
    case energy
    case knockknock = "knock-knock"
    case letterEmail = "letter_email"
    case lose1
    case lose2
    case negative1
    case negative2
    case negative3
    case negative4
    case negative5
    case notification
    case notification2
    case notification3
    case notification4
    case open_door = "openDoor"
    case positive1
    case positive2
    case positive3
    case positive4
    case positive5
    case positive6
    case statistic
    case thunder
    case water1
    case water2
    case win
    case win2
    case wind
    case windShort = "wind_short"
  }

  /// Alarm sounds
  public enum Alarm: String, Codable {
    case alarm1
    case alarm2
    case alarm3
    case alarm4
    case alarm5
    case alarm6
    case alarm7
    case alarm8
    case alarm9
    case alarm10
    case alarm11
    case alarm12
    case alarm13
  }
}

// MARK: Decodables

extension Notification {
  public struct PushResponse: Decodable {
    public struct Success: Decodable {
      public let id: String
    }

    public struct Errors: Swift.Error {
      let messages: [String]
    }

    struct Err: Decodable {
      let message: String
    }

    public let result: Result<Success, Errors>

    enum CodingKeys: CodingKey {
      case success, errors
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      if let error = try container.decodeIfPresent([Err].self, forKey: .errors) {
        result = .failure(.init(messages: error.map({ $0.message })))
      } else if let success = try container.decodeIfPresent(Success.self, forKey: .success) {
        result = .success(success)
      } else {
        throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Unknown response."))
      }
    }
  }
}

// MARK: Helpers

public enum LaMetricError: Error {
  case invalidHostURL
}

#if canImport(UIKit)
import UIKit

// TODO: this should work with macOS too.
@available(iOS 13, *)
@available(watchOS 6, *)
@available(tvOS 13, *)
extension UIImage {
  func scaled() -> UIImage {
    let newSize = CGSize(width: 8, height: 8)
    if (size.width < newSize.width && size.height < newSize.height) {
      return self
    }

    let widthScale = newSize.width / size.width
    let heightScale = newSize.height / size.height

    let scaleFactor = widthScale < heightScale ? widthScale : heightScale
    let scaledSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)

    UIGraphicsBeginImageContext(scaledSize)
    let scaledContext = UIGraphicsGetCurrentContext()!
    scaledContext.interpolationQuality = .none

    draw(in: CGRect(x: 0.0, y: 0.0, width: scaledSize.width, height: scaledSize.height))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return newImage ?? UIImage()
  }
}
#endif
