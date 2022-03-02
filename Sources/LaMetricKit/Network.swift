import Foundation

// MARK: Container

public struct LaMetricKit {
  private let session: URLSession
  private let decoder: JSONDecoder
  private let encoder: JSONEncoder
  private let sessionDelegateHandler: SessionDelegateHandler
  private let configuration: Configuration
}

// MARK: Public

extension LaMetricKit {
  public init(
    _ configuration: Configuration,
    session: URLSession? = nil,
    sessionDelegateHandler: SessionDelegateHandler? = nil
  ) {
    self.session = session ?? URLSession(
      configuration: .default,
      delegate: sessionDelegateHandler ?? .shared,
      delegateQueue: .current
    )

    self.configuration = configuration
    self.sessionDelegateHandler = sessionDelegateHandler ?? .shared
    self.encoder = JSONEncoder()
    self.decoder = JSONDecoder()
  }

  /// Send notification directly to LaMetric  device on local network.
  @discardableResult
  public func push(_ notification: Notification) async throws -> Notification.PushResponse {
    let (data, _) = try await session.data(
      for: buildRequest(
        ip: configuration.ipAddress,
        body: notification,
        apiKey: configuration.apiKey
      )
    )
    let result = try decoder.decode(Notification.PushResponse.self, from: data)
    return result
  }
}

extension LaMetricKit {
  public struct Configuration {
    fileprivate let apiKey: String
    fileprivate let ipAddress: String

    /// API key can be base64 encoded or used raw. Your devices IP address should be v4.
    public init(_ apiKey: String, ipAddress: String) {
      if apiKey.count == 64 {
        self.apiKey = apiKey.data(using: .utf8)!.base64EncodedString()
      } else {
        self.apiKey = apiKey
      }
      self.ipAddress = ipAddress
    }
  }
}

// MARK: Private

extension LaMetricKit {
  private func buildRequest<Body: Encodable>(
    ip: String,
    body: Body,
    apiKey: String
  ) throws -> URLRequest {
    var request = try URLRequest(url: buildURL(from: ip))
    request.httpMethod = "POST"
    request.httpBody = try encoder.encode(body)
    request.setValue(apiKey, forHTTPHeaderField: "X-Access-Token")

    return request
  }

  private func buildURL(from ip: String) throws -> URL {
    var components = URLComponents()
    components.scheme = "https"
    components.host = ip
    components.port = 4343
    components.path = "/api/v1/dev/device/notifications"
    guard let url = components.url else {
      throw LaMetricError.invalidHostURL
    }
    return url
  }

  /// Talking to the device over the local network has a self-signed cert so we just ignore SSL.
  public class SessionDelegateHandler: NSObject, URLSessionDelegate {
    fileprivate static let shared = SessionDelegateHandler()
    public func urlSession(
      _ session: URLSession,
      didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
      let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
      return (.useCredential, credential)
    }
  }
}

// MARK: Backwards compatibility

@available(iOS, deprecated: 15.0, message: "Remove when iOS 15 is the base.")
@available(macOS, deprecated: 12.0, message: "Remove when macOS 12 is the base.")
@available(tvOS, deprecated: 15.0, message: "Remove when tvOS 15 is the base.")
@available(watchOS, deprecated: 8.0, message: "Remove when watchOS 8 is the base.")
extension URLSession {
  /// Adapted from https://github.com/JohnSundell/AsyncCompatibilityKit
  fileprivate func data(for request: URLRequest) async throws -> (Data, URLResponse) {
    let taskBox = TaskBox()
    return try await withTaskCancellationHandler {
      taskBox.value?.cancel()
    } operation: {
      try await withCheckedThrowingContinuation { continuation in
        taskBox.value = self.dataTask(with: request) { data, response, error in
          guard let data = data, let response = response else {
            let error = error ?? URLError(.badServerResponse)
            return continuation.resume(throwing: error)
          }
          continuation.resume(returning: (data, response))
        }
        taskBox.value?.resume()
      }
    }
  }

  fileprivate class TaskBox: @unchecked Sendable {
    private let lock = NSRecursiveLock()
    private var _value: URLSessionDataTask?
    fileprivate var value: URLSessionDataTask? {
      get {
        defer { lock.unlock() }
        lock.lock()
        return _value
      }
      set {
        defer { lock.unlock() }
        lock.lock()
        _value = newValue
      }
    }
  }
}
