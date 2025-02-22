/* Copyright Urban Airship and Contributors */

import SwiftUI
public import Combine

#if canImport(AirshipCore)
import AirshipCore
#endif

/// The message center controller possible states
public enum MessageCenterState: Equatable, Sendable {
    case visible(messageID: String?)
    case notVisible
}

/// Controller for the Message Center View.
@MainActor
public class MessageCenterController: ObservableObject {

    @Published
    var messageID: String? = nil

    @Published
    var visibleMessageID: String? = nil

    @Published
    var isMessageCenterVisible: Bool = false

    private var subscriptions: Set<AnyCancellable> = Set()

    private let updateSubject = PassthroughSubject<MessageCenterState, Never>()

    /// Publisher that emits the message center state.
    public var statePublisher: AnyPublisher<MessageCenterState, Never> {
        self.updateSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    /// Navigates to the message ID.
    /// - Parameters:
    ///     - messageID: The message ID to navigate to.
    public func navigate(messageID: String?) {
        self.messageID = messageID
    }

    public init() {
        Publishers
            .CombineLatest($visibleMessageID, $isMessageCenterVisible)
            .sink {[updateSubject] (visibleMessageID, isMessageCenterVisible) in
                if  let messageID = visibleMessageID {
                    updateSubject.send(.visible(messageID: messageID))
                } else if isMessageCenterVisible {
                    updateSubject.send(.visible(messageID: nil))
                } else {
                    updateSubject.send(.notVisible)
                }
            }
            .store(in: &subscriptions)
    }
}
