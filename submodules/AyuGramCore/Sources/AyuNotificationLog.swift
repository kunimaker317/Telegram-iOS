// This is the source code of AyuGram for iOS.
//
// We do not and cannot prevent the use of our code,
// but be respectful and credit the original author.
//
// Copyright @Radolyn, 2025

import Foundation
import UserNotifications

public struct AyuLogEvent: Codable, Equatable {
    public enum EventType: String, Codable {
        case deleted
        case edited
    }

    public let id: String
    public let type: EventType
    public let timestamp: TimeInterval
    public let chatName: String
    public let senderName: String
    public let messageText: String?

    public init(type: EventType, chatName: String, senderName: String, messageText: String?) {
        self.id = UUID().uuidString
        self.type = type
        self.timestamp = Date().timeIntervalSince1970
        self.chatName = chatName
        self.senderName = senderName
        self.messageText = messageText
    }

    public var formattedDate: String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

/// Stores deletion/edit events and fires local UNUserNotificationCenter notifications.
public final class AyuNotificationLog {
    public static let shared = AyuNotificationLog()

    private static let storageKey = "ayuNotificationLog"
    private static let maxEvents = 500

    private let defaults = UserDefaults.standard
    private let queue = DispatchQueue(label: "AyuNotificationLog", qos: .utility)

    private init() {}

    // MARK: - Storage

    public func allEvents() -> [AyuLogEvent] {
        guard let data = defaults.data(forKey: Self.storageKey),
              let events = try? JSONDecoder().decode([AyuLogEvent].self, from: data) else {
            return []
        }
        return events
    }

    private func save(_ events: [AyuLogEvent]) {
        if let data = try? JSONEncoder().encode(events) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }

    public func append(event: AyuLogEvent) {
        queue.async { [self] in
            var events = allEvents()
            events.insert(event, at: 0)
            if events.count > Self.maxEvents {
                events = Array(events.prefix(Self.maxEvents))
            }
            save(events)
        }
    }

    public func clearAll() {
        defaults.removeObject(forKey: Self.storageKey)
    }

    // MARK: - Local Notifications

    public func log(type: AyuLogEvent.EventType, chatName: String, senderName: String, messageText: String?) {
        guard AyuSettings.shared.ayuNotificationsEnabled else { return }

        let showContent = AyuSettings.shared.ayuNotificationShowContent
        let storedText = showContent ? messageText : nil
        let event = AyuLogEvent(type: type, chatName: chatName, senderName: senderName, messageText: storedText)
        append(event: event)

        let content = UNMutableNotificationContent()
        content.title = "AyuGram"

        let isRu = Locale.current.languageCode == "ru"

        switch type {
        case .deleted:
            if showContent, let text = messageText, !text.isEmpty {
                content.body = isRu
                    ? "\(senderName) \u{443}\u{434}\u{430}\u{43B}\u{438}\u{43B}(\u{430}): \"\(text)\""
                    : "\(senderName) deleted: \"\(text)\""
            } else {
                content.body = isRu
                    ? "\(senderName) \u{443}\u{434}\u{430}\u{43B}\u{438}\u{43B}(\u{430}) \u{441}\u{43E}\u{43E}\u{431}\u{449}\u{435}\u{43D}\u{438}\u{435} \u{432} \(chatName)"
                    : "\(senderName) deleted a message in \(chatName)"
            }
        case .edited:
            if showContent, let text = messageText, !text.isEmpty {
                content.body = isRu
                    ? "\(senderName) \u{438}\u{437}\u{43C}\u{435}\u{43D}\u{438}\u{43B}(\u{430}): \"\(text)\""
                    : "\(senderName) edited: \"\(text)\""
            } else {
                content.body = isRu
                    ? "\(senderName) \u{438}\u{437}\u{43C}\u{435}\u{43D}\u{438}\u{43B}(\u{430}) \u{441}\u{43E}\u{43E}\u{431}\u{449}\u{435}\u{43D}\u{438}\u{435} \u{432} \(chatName)"
                    : "\(senderName) edited a message in \(chatName)"
            }
        }

        content.sound = .default
        content.threadIdentifier = "AyuGram"

        let request = UNNotificationRequest(
            identifier: event.id,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            UNUserNotificationCenter.current().add(request)
        }
    }
}
