public protocol Frame {
  typealias NotificationFrame = Notification.Model.Frame
  func buildFrames() -> [NotificationFrame]
}

extension Notification {
  public init(
    _ priority: Priority? = nil,
    sound: Model.Sound? = nil,
    iconType: IconType? = nil,
    cycles: Int = 1,
    lifetime: Int? = nil,
    @NotificationFramesBuilder frames: () -> [Model.Frame]
  ) {
    self.init(
      frames: frames(),
      sound: sound,
      cycles: cycles,
      priority: priority,
      iconType: iconType,
      lifetime: lifetime
    )
  }
}

public struct EmptyFrame: Frame {
  public init() {}
  public func buildFrames() -> [NotificationFrame] { [] }
}

public struct Simple: Frame {
  private let frame: NotificationFrame
  public func buildFrames() -> [NotificationFrame] { [frame] }

  public init(_ text: String?, icon: Notification.Model.Frame.Icon = .identified(0)) {
    self.frame = .simple(icon: icon, text: text)
  }
}

public struct Chart: Frame {
  private let frame: Notification.Model.Frame
  public func buildFrames() -> [NotificationFrame] { [frame] }

  public init(_ points: [Int]) {
    self.frame = .chart(points: points)
  }
}

public struct Goal: Frame {
  private let frame: Notification.Model.Frame
  public func buildFrames() -> [NotificationFrame] { [frame] }

  public init(
    _ current: Int,
    in range: ClosedRange<Int>,
    unit: String,
    icon: Notification.Model.Frame.Icon = .identified(0)
  ) {
    self.frame = .goal(
      icon: icon,
      start: range.lowerBound,
      current: current,
      end: range.upperBound,
      unit: unit
    )
  }
}

extension Frame {
  /// Repeats a frame by a given amount.
  public func repeats(_ count: Int) -> Frame {
    Array(repeating: self.buildFrames().first!, count: count)
  }
}

extension Array: Frame where Element == Notification.Model.Frame {
  public func buildFrames() -> [NotificationFrame] { self }
}

@resultBuilder
public struct NotificationFramesBuilder {
  public static func buildBlock(_ components: Frame...) -> [Notification.Model.Frame] {
    components.flatMap({ $0.buildFrames() })
  }

  public static func buildOptional(_ value: Frame?) -> Frame {
    value ?? []
  }

  public static func buildEither(first: Frame) -> Frame {
    first
  }

  public static func buildEither(second: Frame) -> Frame {
    second
  }

  public static func buildLimitedAvailability(_ component: [Notification.Model.Frame]) -> [Notification.Model.Frame] {
    component
  }
}
