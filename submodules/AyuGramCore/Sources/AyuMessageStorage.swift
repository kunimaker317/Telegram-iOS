// This is the source code of AyuGram for iOS.
//
// We do not and cannot prevent the use of our code,
// but be respectful and credit the original author.
//
// Copyright @Radolyn, 2025

import Foundation
import SQLite3

public struct AyuDeletedMessage: Codable {
    public let messageId: Int32
    public let peerId: Int64
    public let fromId: Int64?
    public let date: Int32
    public let text: String
    public let savedAt: Int32

    public init(messageId: Int32, peerId: Int64, fromId: Int64?, date: Int32, text: String, savedAt: Int32) {
        self.messageId = messageId
        self.peerId = peerId
        self.fromId = fromId
        self.date = date
        self.text = text
        self.savedAt = savedAt
    }
}

public struct AyuEditedMessage: Codable {
    public let messageId: Int32
    public let peerId: Int64
    public let fromId: Int64?
    public let date: Int32
    public let prevText: String
    public let newText: String
    public let savedAt: Int32

    public init(messageId: Int32, peerId: Int64, fromId: Int64?, date: Int32, prevText: String, newText: String, savedAt: Int32) {
        self.messageId = messageId
        self.peerId = peerId
        self.fromId = fromId
        self.date = date
        self.prevText = prevText
        self.newText = newText
        self.savedAt = savedAt
    }
}

public final class AyuMessageStorage {
    public static let shared = AyuMessageStorage()

    private var db: OpaquePointer?
    private let queue = DispatchQueue(label: "one.ayugram.storage", qos: .utility)

    private init() {
        setupDatabase()
    }

    private func dbPath() -> String {
        let dir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.ph.telegra.Telegraph")
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return dir.appendingPathComponent("ayu_messages.db").path
    }

    private func setupDatabase() {
        queue.async { [weak self] in
            guard let self else { return }
            if sqlite3_open(self.dbPath(), &self.db) == SQLITE_OK {
                self.execute("""
                    CREATE TABLE IF NOT EXISTS deleted_messages (
                        message_id INTEGER,
                        peer_id INTEGER,
                        from_id INTEGER,
                        date INTEGER,
                        text TEXT,
                        saved_at INTEGER,
                        PRIMARY KEY (message_id, peer_id)
                    )
                """)
                self.execute("""
                    CREATE TABLE IF NOT EXISTS edited_messages (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        message_id INTEGER,
                        peer_id INTEGER,
                        from_id INTEGER,
                        date INTEGER,
                        prev_text TEXT,
                        new_text TEXT,
                        saved_at INTEGER
                    )
                """)
            }
        }
    }

    @discardableResult
    private func execute(_ sql: String) -> Bool {
        var err: UnsafeMutablePointer<Int8>?
        return sqlite3_exec(db, sql, nil, nil, &err) == SQLITE_OK
    }

    // MARK: - Public API

    public func saveDeletedMessage(messageId: Int32, peerId: Int64, fromId: Int64?, date: Int32, text: String) {
        guard AyuSettings.shared.saveDeletedMessages else { return }
        queue.async { [weak self] in
            guard let self, let db = self.db else { return }
            let sql = "INSERT OR REPLACE INTO deleted_messages (message_id, peer_id, from_id, date, text, saved_at) VALUES (?,?,?,?,?,?)"
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_int(stmt, 1, messageId)
                sqlite3_bind_int64(stmt, 2, peerId)
                if let fromId { sqlite3_bind_int64(stmt, 3, fromId) } else { sqlite3_bind_null(stmt, 3) }
                sqlite3_bind_int(stmt, 4, date)
                sqlite3_bind_text(stmt, 5, (text as NSString).utf8String, -1, nil)
                sqlite3_bind_int(stmt, 6, Int32(Date().timeIntervalSince1970))
                sqlite3_step(stmt)
                sqlite3_finalize(stmt)
            }
        }
    }

    public func saveEditedMessage(messageId: Int32, peerId: Int64, fromId: Int64?, date: Int32, prevText: String, newText: String) {
        guard AyuSettings.shared.saveMessagesHistory else { return }
        queue.async { [weak self] in
            guard let self, let db = self.db else { return }
            let sql = "INSERT INTO edited_messages (message_id, peer_id, from_id, date, prev_text, new_text, saved_at) VALUES (?,?,?,?,?,?,?)"
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_int(stmt, 1, messageId)
                sqlite3_bind_int64(stmt, 2, peerId)
                if let fromId { sqlite3_bind_int64(stmt, 3, fromId) } else { sqlite3_bind_null(stmt, 3) }
                sqlite3_bind_int(stmt, 4, date)
                sqlite3_bind_text(stmt, 5, (prevText as NSString).utf8String, -1, nil)
                sqlite3_bind_text(stmt, 6, (newText as NSString).utf8String, -1, nil)
                sqlite3_bind_int(stmt, 7, Int32(Date().timeIntervalSince1970))
                sqlite3_step(stmt)
                sqlite3_finalize(stmt)
            }
        }
    }

    public func getDeletedMessages(peerId: Int64) -> [AyuDeletedMessage] {
        var result: [AyuDeletedMessage] = []
        queue.sync { [weak self] in
            guard let self, let db = self.db else { return }
            let sql = "SELECT message_id, peer_id, from_id, date, text, saved_at FROM deleted_messages WHERE peer_id = ? ORDER BY date DESC"
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_int64(stmt, 1, peerId)
                while sqlite3_step(stmt) == SQLITE_ROW {
                    let msg = AyuDeletedMessage(
                        messageId: sqlite3_column_int(stmt, 0),
                        peerId: sqlite3_column_int64(stmt, 1),
                        fromId: sqlite3_column_type(stmt, 2) != SQLITE_NULL ? sqlite3_column_int64(stmt, 2) : nil,
                        date: sqlite3_column_int(stmt, 3),
                        text: String(cString: sqlite3_column_text(stmt, 4)),
                        savedAt: sqlite3_column_int(stmt, 5)
                    )
                    result.append(msg)
                }
                sqlite3_finalize(stmt)
            }
        }
        return result
    }

    public func getEditedMessages(messageId: Int32, peerId: Int64) -> [AyuEditedMessage] {
        var result: [AyuEditedMessage] = []
        queue.sync { [weak self] in
            guard let self, let db = self.db else { return }
            let sql = "SELECT message_id, peer_id, from_id, date, prev_text, new_text, saved_at FROM edited_messages WHERE message_id = ? AND peer_id = ? ORDER BY saved_at ASC"
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_int(stmt, 1, messageId)
                sqlite3_bind_int64(stmt, 2, peerId)
                while sqlite3_step(stmt) == SQLITE_ROW {
                    let msg = AyuEditedMessage(
                        messageId: sqlite3_column_int(stmt, 0),
                        peerId: sqlite3_column_int64(stmt, 1),
                        fromId: sqlite3_column_type(stmt, 2) != SQLITE_NULL ? sqlite3_column_int64(stmt, 2) : nil,
                        date: sqlite3_column_int(stmt, 3),
                        prevText: String(cString: sqlite3_column_text(stmt, 4)),
                        newText: String(cString: sqlite3_column_text(stmt, 5)),
                        savedAt: sqlite3_column_int(stmt, 6)
                    )
                    result.append(msg)
                }
                sqlite3_finalize(stmt)
            }
        }
        return result
    }
}
