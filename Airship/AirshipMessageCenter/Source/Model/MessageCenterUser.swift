/* Copyright Airship and Contributors */

#if canImport(AirshipCore)
import AirshipCore
#endif

/// Model object for holding user data.
public final class MessageCenterUser: NSObject, Codable, Sendable {

    /// The username.
    public let password: String

    /// The password.
    public let username: String

    /// - Note: for internal use only.  :nodoc:
    init(username: String, password: String) {
        self.username = username
        self.password = password
    }

    private enum CodingKeys: String, CodingKey {
        case username = "user_id"
        case password = "password"
    }
}

extension MessageCenterUser {
    public var basicAuthString: String {
        return AirshipUtils.authHeader(
            username: self.username,
            password: self.password
        ) ?? ""
    }
}
