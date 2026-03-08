// This is the source code of AyuGram for iOS.
//
// We do not and cannot prevent the use of our code,
// but be respectful and credit the original author.
//
// Copyright @Radolyn, 2025

import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext
import AyuGramCore

private struct AyuGeneralState: Equatable {
    var saveDeletedMessages: Bool
    var saveMessagesHistory: Bool
    var saveForBots: Bool
    var localPremium: Bool
    var disableAds: Bool
    var disableStories: Bool
    var showPeerId: Int
    var showMessageSeconds: Bool
    var deletedMark: String
    var editedMark: String
    var collapseSimilarChannels: Bool
    var hideSimilarChannels: Bool
    var showOnlyAddedEmojisAndStickers: Bool

    static func current() -> AyuGeneralState {
        let s = AyuSettings.shared
        return AyuGeneralState(
            saveDeletedMessages: s.saveDeletedMessages,
            saveMessagesHistory: s.saveMessagesHistory,
            saveForBots: s.saveForBots,
            localPremium: s.localPremium,
            disableAds: s.disableAds,
            disableStories: s.disableStories,
            showPeerId: s.showPeerId,
            showMessageSeconds: s.showMessageSeconds,
            deletedMark: s.deletedMark,
            editedMark: s.editedMark,
            collapseSimilarChannels: s.collapseSimilarChannels,
            hideSimilarChannels: s.hideSimilarChannels,
            showOnlyAddedEmojisAndStickers: s.showOnlyAddedEmojisAndStickers
        )
    }
}

private final class AyuGeneralArguments {
    let toggleBool: (AyuGeneralBoolSetting) -> Void
    let setShowPeerId: (Int) -> Void
    let setDeletedMark: (String) -> Void
    let setEditedMark: (String) -> Void
    init(
        toggleBool: @escaping (AyuGeneralBoolSetting) -> Void,
        setShowPeerId: @escaping (Int) -> Void,
        setDeletedMark: @escaping (String) -> Void,
        setEditedMark: @escaping (String) -> Void
    ) {
        self.toggleBool = toggleBool
        self.setShowPeerId = setShowPeerId
        self.setDeletedMark = setDeletedMark
        self.setEditedMark = setEditedMark
    }
}

enum AyuGeneralBoolSetting {
    case saveDeletedMessages
    case saveMessagesHistory
    case saveForBots
    case localPremium
    case disableAds
    case disableStories
    case showMessageSeconds
    case collapseSimilarChannels
    case hideSimilarChannels
    case showOnlyAddedEmojisAndStickers
}

private enum AyuGeneralSection: Int32 {
    case history
    case premium
    case interface
    case channels
}

private enum AyuGeneralEntry: ItemListNodeEntry {
    case historyHeader
    case saveDeletedMessages(Bool)
    case saveMessagesHistory(Bool)
    case saveForBots(Bool)
    case historyFooter

    case premiumHeader
    case localPremium(Bool)
    case disableAds(Bool)
    case disableStories(Bool)

    case interfaceHeader
    case showPeerId(Int)
    case showMessageSeconds(Bool)
    case deletedMark(String)
    case editedMark(String)

    case channelsHeader
    case collapseSimilarChannels(Bool)
    case hideSimilarChannels(Bool)
    case showOnlyAddedEmojisAndStickers(Bool)

    var section: ItemListSectionId {
        switch self {
        case .historyHeader, .saveDeletedMessages, .saveMessagesHistory, .saveForBots, .historyFooter:
            return AyuGeneralSection.history.rawValue
        case .premiumHeader, .localPremium, .disableAds, .disableStories:
            return AyuGeneralSection.premium.rawValue
        case .interfaceHeader, .showPeerId, .showMessageSeconds, .deletedMark, .editedMark:
            return AyuGeneralSection.interface.rawValue
        case .channelsHeader, .collapseSimilarChannels, .hideSimilarChannels, .showOnlyAddedEmojisAndStickers:
            return AyuGeneralSection.channels.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .historyHeader: return 0
        case .saveDeletedMessages: return 1
        case .saveMessagesHistory: return 2
        case .saveForBots: return 3
        case .historyFooter: return 4
        case .premiumHeader: return 5
        case .localPremium: return 6
        case .disableAds: return 7
        case .disableStories: return 8
        case .interfaceHeader: return 9
        case .showPeerId: return 10
        case .showMessageSeconds: return 11
        case .deletedMark: return 12
        case .editedMark: return 13
        case .channelsHeader: return 14
        case .collapseSimilarChannels: return 15
        case .hideSimilarChannels: return 16
        case .showOnlyAddedEmojisAndStickers: return 17
        }
    }

    static func < (lhs: AyuGeneralEntry, rhs: AyuGeneralEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! AyuGeneralArguments
        switch self {
        case .historyHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "MESSAGE HISTORY", sectionId: self.section)
        case let .saveDeletedMessages(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Save Deleted Messages", value: value, sectionId: self.section, style: .blocks, updated: { _ in arguments.toggleBool(.saveDeletedMessages) })
        case let .saveMessagesHistory(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Save Edited Messages", value: value, sectionId: self.section, style: .blocks, updated: { _ in arguments.toggleBool(.saveMessagesHistory) })
        case let .saveForBots(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Save History for Bots", value: value, sectionId: self.section, style: .blocks, updated: { _ in arguments.toggleBool(.saveForBots) })
        case .historyFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Keeps a local copy of deleted and edited messages."), sectionId: self.section)
        case .premiumHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "PREMIUM", sectionId: self.section)
        case let .localPremium(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Local Telegram Premium", value: value, sectionId: self.section, style: .blocks, updated: { _ in arguments.toggleBool(.localPremium) })
        case let .disableAds(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Disable Ads", value: value, sectionId: self.section, style: .blocks, updated: { _ in arguments.toggleBool(.disableAds) })
        case let .disableStories(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Disable Stories", value: value, sectionId: self.section, style: .blocks, updated: { _ in arguments.toggleBool(.disableStories) })
        case .interfaceHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "INTERFACE", sectionId: self.section)
        case let .showPeerId(value):
            let label: String
            switch value {
            case 0: label = "Hidden"
            case 1: label = "In Profile"
            case 2: label = "Everywhere"
            default: label = "Hidden"
            }
            return ItemListDisclosureItem(presentationData: presentationData, title: "Show Peer ID", label: label, sectionId: self.section, style: .blocks, action: {
                let next = (value + 1) % 3
                arguments.setShowPeerId(next)
            })
        case let .showMessageSeconds(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Show Message Seconds", value: value, sectionId: self.section, style: .blocks, updated: { _ in arguments.toggleBool(.showMessageSeconds) })
        case let .deletedMark(value):
            return ItemListDisclosureItem(presentationData: presentationData, title: "Deleted Mark", label: value, sectionId: self.section, style: .blocks, action: {})
        case let .editedMark(value):
            return ItemListDisclosureItem(presentationData: presentationData, title: "Edited Mark", label: value, sectionId: self.section, style: .blocks, action: {})
        case .channelsHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "CHANNELS", sectionId: self.section)
        case let .collapseSimilarChannels(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Collapse Similar Channels", value: value, sectionId: self.section, style: .blocks, updated: { _ in arguments.toggleBool(.collapseSimilarChannels) })
        case let .hideSimilarChannels(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Hide Similar Channels", value: value, sectionId: self.section, style: .blocks, updated: { _ in arguments.toggleBool(.hideSimilarChannels) })
        case let .showOnlyAddedEmojisAndStickers(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Show Only Added Stickers & Emojis", value: value, sectionId: self.section, style: .blocks, updated: { _ in arguments.toggleBool(.showOnlyAddedEmojisAndStickers) })
        }
    }
}

private func generalEntries(state: AyuGeneralState) -> [AyuGeneralEntry] {
    return [
        .historyHeader,
        .saveDeletedMessages(state.saveDeletedMessages),
        .saveMessagesHistory(state.saveMessagesHistory),
        .saveForBots(state.saveForBots),
        .historyFooter,
        .premiumHeader,
        .localPremium(state.localPremium),
        .disableAds(state.disableAds),
        .disableStories(state.disableStories),
        .interfaceHeader,
        .showPeerId(state.showPeerId),
        .showMessageSeconds(state.showMessageSeconds),
        .deletedMark(state.deletedMark),
        .editedMark(state.editedMark),
        .channelsHeader,
        .collapseSimilarChannels(state.collapseSimilarChannels),
        .hideSimilarChannels(state.hideSimilarChannels),
        .showOnlyAddedEmojisAndStickers(state.showOnlyAddedEmojisAndStickers),
    ]
}

public func ayuGeneralController(context: AccountContext) -> ViewController {
    let statePromise = ValuePromise(AyuGeneralState.current(), ignoreRepeated: true)
    let stateValue = Atomic(value: AyuGeneralState.current())

    let updateState: ((AyuGeneralState) -> AyuGeneralState) -> Void = { f in
        statePromise.set(stateValue.modify { f($0) })
    }

    let arguments = AyuGeneralArguments(
        toggleBool: { setting in
            let s = AyuSettings.shared
            switch setting {
            case .saveDeletedMessages: s.saveDeletedMessages = !s.saveDeletedMessages
            case .saveMessagesHistory: s.saveMessagesHistory = !s.saveMessagesHistory
            case .saveForBots: s.saveForBots = !s.saveForBots
            case .localPremium: s.localPremium = !s.localPremium
            case .disableAds: s.disableAds = !s.disableAds
            case .disableStories: s.disableStories = !s.disableStories
            case .showMessageSeconds: s.showMessageSeconds = !s.showMessageSeconds
            case .collapseSimilarChannels: s.collapseSimilarChannels = !s.collapseSimilarChannels
            case .hideSimilarChannels: s.hideSimilarChannels = !s.hideSimilarChannels
            case .showOnlyAddedEmojisAndStickers: s.showOnlyAddedEmojisAndStickers = !s.showOnlyAddedEmojisAndStickers
            }
            updateState { _ in AyuGeneralState.current() }
        },
        setShowPeerId: { value in
            AyuSettings.shared.showPeerId = value
            updateState { _ in AyuGeneralState.current() }
        },
        setDeletedMark: { value in
            AyuSettings.shared.deletedMark = value
            updateState { _ in AyuGeneralState.current() }
        },
        setEditedMark: { value in
            AyuSettings.shared.editedMark = value
            updateState { _ in AyuGeneralState.current() }
        }
    )

    let signal = combineLatest(
        context.sharedContext.presentationData,
        statePromise.get()
    )
    |> deliverOnMainQueue
    |> map { presentationData, state -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("General"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: generalEntries(state: state),
            style: .blocks,
            animateChanges: true
        )
        return (controllerState, (listState, arguments))
    }

    return ItemListController(context: context, state: signal)
}
