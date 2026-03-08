// This is the source code of AyuGram for iOS.
//
// We do not and cannot prevent the use of our code,
// but be respectful and credit the original author.
//
// Copyright @Radolyn, 2025

import Foundation

public final class AyuSettings {
    public static let shared = AyuSettings()

    private let defaults = UserDefaults.standard

    private init() {}

    // MARK: - Ghost Mode

    public var sendReadMessages: Bool {
        get { defaults.object(forKey: "sendReadMessages") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "sendReadMessages") }
    }

    public var sendReadStories: Bool {
        get { defaults.object(forKey: "sendReadStories") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "sendReadStories") }
    }

    public var sendOnlinePackets: Bool {
        get { defaults.object(forKey: "sendOnlinePackets") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "sendOnlinePackets") }
    }

    public var sendUploadProgress: Bool {
        get { defaults.object(forKey: "sendUploadProgress") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "sendUploadProgress") }
    }

    public var sendOfflinePacketAfterOnline: Bool {
        get { defaults.object(forKey: "sendOfflinePacketAfterOnline") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "sendOfflinePacketAfterOnline") }
    }

    public var markReadAfterAction: Bool {
        get { defaults.object(forKey: "markReadAfterAction") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "markReadAfterAction") }
    }

    public var useScheduledMessages: Bool {
        get { defaults.object(forKey: "useScheduledMessages") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "useScheduledMessages") }
    }

    public var sendWithoutSound: Bool {
        get { defaults.object(forKey: "sendWithoutSound") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "sendWithoutSound") }
    }

    // MARK: - Message History

    public var saveDeletedMessages: Bool {
        get { defaults.object(forKey: "saveDeletedMessages") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "saveDeletedMessages") }
    }

    public var saveMessagesHistory: Bool {
        get { defaults.object(forKey: "saveMessagesHistory") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "saveMessagesHistory") }
    }

    public var saveForBots: Bool {
        get { defaults.object(forKey: "saveForBots") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "saveForBots") }
    }

    // MARK: - Filters

    public var filtersEnabled: Bool {
        get { defaults.object(forKey: "filtersEnabled") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "filtersEnabled") }
    }

    public var filtersEnabledInChats: Bool {
        get { defaults.object(forKey: "filtersEnabledInChats") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "filtersEnabledInChats") }
    }

    public var hideFromBlocked: Bool {
        get { defaults.object(forKey: "hideFromBlocked") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "hideFromBlocked") }
    }

    public var shadowBanIds: [Int64] {
        get { defaults.object(forKey: "shadowBanIds") as? [Int64] ?? [] }
        set { defaults.set(newValue, forKey: "shadowBanIds") }
    }

    // MARK: - General

    public var disableAds: Bool {
        get { defaults.object(forKey: "disableAds") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "disableAds") }
    }

    public var disableStories: Bool {
        get { defaults.object(forKey: "disableStories") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "disableStories") }
    }

    public var disableCustomBackgrounds: Bool {
        get { defaults.object(forKey: "disableCustomBackgrounds") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "disableCustomBackgrounds") }
    }

    public var localPremium: Bool {
        get { defaults.object(forKey: "localPremium") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "localPremium") }
    }

    public var showPeerId: Int {
        get { defaults.object(forKey: "showPeerId") as? Int ?? 0 }
        set { defaults.set(newValue, forKey: "showPeerId") }
    }

    public var showMessageSeconds: Bool {
        get { defaults.object(forKey: "showMessageSeconds") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "showMessageSeconds") }
    }

    public var deletedMark: String {
        get { defaults.object(forKey: "deletedMark") as? String ?? "🧹" }
        set { defaults.set(newValue, forKey: "deletedMark") }
    }

    public var editedMark: String {
        get { defaults.object(forKey: "editedMark") as? String ?? "✏️" }
        set { defaults.set(newValue, forKey: "editedMark") }
    }

    public var recentStickersCount: Int {
        get { defaults.object(forKey: "recentStickersCount") as? Int ?? 20 }
        set { defaults.set(newValue, forKey: "recentStickersCount") }
    }

    public var showOnlyAddedEmojisAndStickers: Bool {
        get { defaults.object(forKey: "showOnlyAddedEmojisAndStickers") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "showOnlyAddedEmojisAndStickers") }
    }

    public var collapseSimilarChannels: Bool {
        get { defaults.object(forKey: "collapseSimilarChannels") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "collapseSimilarChannels") }
    }

    public var hideSimilarChannels: Bool {
        get { defaults.object(forKey: "hideSimilarChannels") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "hideSimilarChannels") }
    }

    // MARK: - Appearance

    public var removeMessageTail: Bool {
        get { defaults.object(forKey: "removeMessageTail") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "removeMessageTail") }
    }

    public var simpleQuotesAndReplies: Bool {
        get { defaults.object(forKey: "simpleQuotesAndReplies") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "simpleQuotesAndReplies") }
    }

    public var adaptiveCoverColor: Bool {
        get { defaults.object(forKey: "adaptiveCoverColor") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "adaptiveCoverColor") }
    }

    public var hideNotificationCounters: Bool {
        get { defaults.object(forKey: "hideNotificationCounters") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "hideNotificationCounters") }
    }

    public var hideNotificationBadge: Bool {
        get { defaults.object(forKey: "hideNotificationBadge") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "hideNotificationBadge") }
    }

    public var hideAllChatsFolder: Bool {
        get { defaults.object(forKey: "hideAllChatsFolder") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "hideAllChatsFolder") }
    }

    // MARK: - Chats

    public var disableNotificationsDelay: Bool {
        get { defaults.object(forKey: "disableNotificationsDelay") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "disableNotificationsDelay") }
    }

    public var stickerConfirmation: Bool {
        get { defaults.object(forKey: "stickerConfirmation") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "stickerConfirmation") }
    }

    public var gifConfirmation: Bool {
        get { defaults.object(forKey: "gifConfirmation") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "gifConfirmation") }
    }

    public var voiceConfirmation: Bool {
        get { defaults.object(forKey: "voiceConfirmation") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "voiceConfirmation") }
    }

    // MARK: - Other

    public var translationProvider: String {
        get { defaults.object(forKey: "translationProvider") as? String ?? "Google" }
        set { defaults.set(newValue, forKey: "translationProvider") }
    }

    public var crashReporting: Bool {
        get { defaults.object(forKey: "crashReporting") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "crashReporting") }
    }

    // MARK: - Ghost mode helper

    public var isGhostModeActive: Bool {
        return !sendReadMessages || !sendReadStories || !sendOnlinePackets || !sendUploadProgress
    }
}
