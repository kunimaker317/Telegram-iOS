// This is the source code of AyuGram for iOS.
//
// We do not and cannot prevent the use of our code,
// but be respectful and credit the original author.
//
// Copyright @Radolyn, 2025

import Foundation

public struct AyuDeletedMessage: Codable {
    public let messageId: Int32
    public let peerId: Int64
    public let fromId: Int64?
    public let date: Int32
    public let text: String

    public init(messageId: Int32, peerId: Int64, fromId: Int64?, date: Int32, text: String) {
        self.messageId = messageId
        self.peerId = peerId
        self.fromId = fromId
        self.date = date
        self.text = text
    }
}

public struct AyuEditedMessage: Codable {
    public let messageId: Int32
    public let peerId: Int64
    public let fromId: Int64?
    public let date: Int32
    public let prevText: String
    public let newText: String

    public init(messageId: Int32, peerId: Int64, fromId: Int64?, date: Int32, prevText: String, newText: String) {
        self.messageId = messageId
        self.peerId = peerId
        self.fromId = fromId
        self.date = date
        self.prevText = prevText
        self.newText = newText
    }
}

public final class AyuMessageStorage {
    public static let shared = AyuMessageStorage()

    private let queue = DispatchQueue(label: "one.ayugram.storage", qos: .utility)
    private let containerURL: URL?

    private init() {
        containerURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }

    private func fileURL(_ name: String) -> URL? {
        return containerURL?.appendingPathComponent("ayu_\(name).json")
    }

    private func load<T: Codable>(_ name: String) -> [T] {
        guard let url = fileURL(name),
              let data = try? Data(contentsOf: url),
              let items = try? JSONDecoder().decode([T].self, from: data) else {
            return []
        }
        return items
    }

    private func save<T: Codable>(_ name: String, items: [T]) {
        guard let url = fileURL(name),
              let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: url, options: .atomic)
    }

    public func saveDeletedMessage(messageId: Int32, peerId: Int64, fromId: Int64?, date: Int32, text: String) {
        guard AyuSettings.shared.saveDeletedMessages else { return }
        queue.async {
            var items: [AyuDeletedMessage] = self.load("deleted")
            guard !items.contains(where: { $0.messageId == messageId && $0.peerId == peerId }) else { return }
            items.append(AyuDeletedMessage(messageId: messageId, peerId: peerId, fromId: fromId, date: date, text: text))
            self.save("deleted", items: items)
        }
    }

    public func saveEditedMessage(messageId: Int32, peerId: Int64, fromId: Int64?, date: Int32, prevText: String, newText: String) {
        guard AyuSettings.shared.saveMessagesHistory else { return }
        queue.async {
            var items: [AyuEditedMessage] = self.load("edited")
            items.append(AyuEditedMessage(messageId: messageId, peerId: peerId, fromId: fromId, date: date, prevText: prevText, newText: newText))
            self.save("edited", items: items)
        }
    }

    public func getDeletedMessages(peerId: Int64) -> [AyuDeletedMessage] {
        var result: [AyuDeletedMessage] = []
        queue.sync {
            let items: [AyuDeletedMessage] = self.load("deleted")
            result = items.filter { $0.peerId == peerId }.sorted { $0.date > $1.date }
        }
        return result
    }

    public func getEditedMessages(messageId: Int32, peerId: Int64) -> [AyuEditedMessage] {
        var result: [AyuEditedMessage] = []
        queue.sync {
            let items: [AyuEditedMessage] = self.load("edited")
            result = items.filter { $0.messageId == messageId && $0.peerId == peerId }
        }
        return result
    }
}
