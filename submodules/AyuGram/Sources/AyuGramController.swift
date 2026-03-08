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
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext
import AyuGramCore

private struct AyuGramState: Equatable {
    var sendReadMessages: Bool
    var sendReadStories: Bool
    var sendOnlinePackets: Bool
    var sendUploadProgress: Bool
    var sendOfflinePacketAfterOnline: Bool
    var markReadAfterAction: Bool
    var useScheduledMessages: Bool
    var sendWithoutSound: Bool
    var saveDeletedMessages: Bool
    var saveMessagesHistory: Bool
    var saveForBots: Bool
    var localPremium: Bool
    var disableAds: Bool

    static func current() -> AyuGramState {
        let s = AyuSettings.shared
        return AyuGramState(
            sendReadMessages: s.sendReadMessages,
            sendReadStories: s.sendReadStories,
            sendOnlinePackets: s.sendOnlinePackets,
            sendUploadProgress: s.sendUploadProgress,
            sendOfflinePacketAfterOnline: s.sendOfflinePacketAfterOnline,
            markReadAfterAction: s.markReadAfterAction,
            useScheduledMessages: s.useScheduledMessages,
            sendWithoutSound: s.sendWithoutSound,
            saveDeletedMessages: s.saveDeletedMessages,
            saveMessagesHistory: s.saveMessagesHistory,
            saveForBots: s.saveForBots,
            localPremium: s.localPremium,
            disableAds: s.disableAds
        )
    }
}

private enum AyuGramSection: Int32 {
    case ghost
    case actions
    case spy
    case other
}

private enum AyuGramEntry: ItemListNodeEntry {
    case ghostHeader
    case sendReadMessages(Bool)
    case sendReadStories(Bool)
    case sendOnlinePackets(Bool)
    case sendUploadProgress(Bool)
    case sendOfflinePacketAfterOnline(Bool)
    case ghostFooter

    case actionsHeader
    case markReadAfterAction(Bool)
    case useScheduledMessages(Bool)
    case sendWithoutSound(Bool)

    case spyHeader
    case saveDeletedMessages(Bool)
    case saveMessagesHistory(Bool)
    case saveForBots(Bool)

    case otherHeader
    case localPremium(Bool)
    case disableAds(Bool)

    var section: ItemListSectionId {
        switch self {
        case .ghostHeader, .sendReadMessages, .sendReadStories,
             .sendOnlinePackets, .sendUploadProgress,
             .sendOfflinePacketAfterOnline, .ghostFooter:
            return AyuGramSection.ghost.rawValue
        case .actionsHeader, .markReadAfterAction,
             .useScheduledMessages, .sendWithoutSound:
            return AyuGramSection.actions.rawValue
        case .spyHeader, .saveDeletedMessages, .saveMessagesHistory, .saveForBots:
            return AyuGramSection.spy.rawValue
        case .otherHeader, .localPremium, .disableAds:
            return AyuGramSection.other.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .ghostHeader: return 0
        case .sendReadMessages: return 1
        case .sendReadStories: return 2
        case .sendOnlinePackets: return 3
        case .sendUploadProgress: return 4
        case .sendOfflinePacketAfterOnline: return 5
        case .ghostFooter: return 6
        case .actionsHeader: return 7
        case .markReadAfterAction: return 8
        case .useScheduledMessages: return 9
        case .sendWithoutSound: return 10
        case .spyHeader: return 11
        case .saveDeletedMessages: return 12
        case .saveMessagesHistory: return 13
        case .saveForBots: return 14
        case .otherHeader: return 15
        case .localPremium: return 16
        case .disableAds: return 17
        }
    }

    static func < (lhs: AyuGramEntry, rhs: AyuGramEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! AyuGramArguments
        switch self {
        case .ghostHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "GHOST ESSENTIALS", sectionId: self.section)
        case let .sendReadMessages(v):
            return ItemListSwitchItem(presentationData: presentationData, title: "Don't Read Messages", value: !v, sectionId: self.section, style: .blocks, updated: { _ in args.toggle(.sendReadMessages) })
        case let .sendReadStories(v):
            return ItemListSwitchItem(presentationData: presentationData, title: "Don't Read Stories", value: !v, sectionId: self.section, style: .blocks, updated: { _ in args.toggle(.sendReadStories) })
        case let .sendOnlinePackets(v):
            return ItemListSwitchItem(presentationData: presentationData, title: "Don't Send Online", value: !v, sectionId: self.section, style: .blocks, updated: { _ in args.toggle(.sendOnlinePackets) })
        case let .sendUploadProgress(v):
            return ItemListSwitchItem(presentationData: presentationData, title: "Don't Send Typing", value: !v, sectionId: self.section, style: .blocks, updated: { _ in args.toggle(.sendUploadProgress) })
        case let .sendOfflinePacketAfterOnline(v):
            return ItemListSwitchItem(presentationData: presentationData, title: "Go Offline Automatically", value: v, sectionId: self.section, style: .blocks, updated: { _ in args.toggle(.sendOfflinePacketAfterOnline) })
        case .ghostFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Ghost mode hides your online activity from others."), sectionId: self.section)
        case .actionsHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "ACTIONS", sectionId: self.section)
        case let .markReadAfterAction(v):
            return ItemListSwitchItem(presentationData: presentationData, title: "Read on Interact", value: v, sectionId: self.section, style: .blocks, updated: { _ in args.toggle(.markReadAfterAction) })
        case let .useScheduledMessages(v):
            return ItemListSwitchItem(presentationData: presentationData, title: "Schedule Messages", value: v, sectionId: self.section, style: .blocks, updated: { _ in args.toggle(.useScheduledMessages) })
        case let .sendWithoutSound(v):
            return ItemListSwitchItem(presentationData: presentationData, title: "Send without Sound", value: v, sectionId: self.section, style: .blocks, updated: { _ in args.toggle(.sendWithoutSound) })
        case .spyHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "SPY ESSENTIALS", sectionId: self.section)
        case let .saveDeletedMessages(v):
            return ItemListSwitchItem(presentationData: presentationData, title: "Save Deleted Messages", value: v, sectionId: self.section, style: .blocks, updated: { _ in args.toggle(.saveDeletedMessages) })
        case let .saveMessagesHistory(v):
            return ItemListSwitchItem(presentationData: presentationData, title: "Save Edits History", value: v, sectionId: self.section, style: .blocks, updated: { _ in args.toggle(.saveMessagesHistory) })
        case let .saveForBots(v):
            return ItemListSwitchItem(presentationData: presentationData, title: "Save in Bot Dialogs", value: v, sectionId: self.section, style: .blocks, updated: { _ in args.toggle(.saveForBots) })
        case .otherHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "OTHER", sectionId: self.section)
        case let .localPremium(v):
            return ItemListSwitchItem(presentationData: presentationData, title: "Local Telegram Premium", value: v, sectionId: self.section, style: .blocks, updated: { _ in args.toggle(.localPremium) })
        case let .disableAds(v):
            return ItemListSwitchItem(presentationData: presentationData, title: "Disable Ads", value: v, sectionId: self.section, style: .blocks, updated: { _ in args.toggle(.disableAds) })
        }
    }
}

private enum AyuGramToggle {
    case sendReadMessages, sendReadStories, sendOnlinePackets, sendUploadProgress
    case sendOfflinePacketAfterOnline, markReadAfterAction, useScheduledMessages, sendWithoutSound
    case saveDeletedMessages, saveMessagesHistory, saveForBots, localPremium, disableAds
}

private final class AyuGramArguments {
    let toggle: (AyuGramToggle) -> Void
    init(toggle: @escaping (AyuGramToggle) -> Void) { self.toggle = toggle }
}

private func ayuGramEntries(state: AyuGramState) -> [AyuGramEntry] {
    return [
        .ghostHeader,
        .sendReadMessages(state.sendReadMessages),
        .sendReadStories(state.sendReadStories),
        .sendOnlinePackets(state.sendOnlinePackets),
        .sendUploadProgress(state.sendUploadProgress),
        .sendOfflinePacketAfterOnline(state.sendOfflinePacketAfterOnline),
        .ghostFooter,
        .actionsHeader,
        .markReadAfterAction(state.markReadAfterAction),
        .useScheduledMessages(state.useScheduledMessages),
        .sendWithoutSound(state.sendWithoutSound),
        .spyHeader,
        .saveDeletedMessages(state.saveDeletedMessages),
        .saveMessagesHistory(state.saveMessagesHistory),
        .saveForBots(state.saveForBots),
        .otherHeader,
        .localPremium(state.localPremium),
        .disableAds(state.disableAds),
    ]
}

public func ayuGramController(context: AccountContext) -> ViewController {
    let statePromise = ValuePromise(AyuGramState.current(), ignoreRepeated: true)
    let stateValue = Atomic(value: AyuGramState.current())

    let updateState: ((AyuGramState) -> AyuGramState) -> Void = { f in
        statePromise.set(stateValue.modify { f($0) })
    }

    let arguments = AyuGramArguments(toggle: { setting in
        let s = AyuSettings.shared
        switch setting {
        case .sendReadMessages: s.sendReadMessages = !s.sendReadMessages
        case .sendReadStories: s.sendReadStories = !s.sendReadStories
        case .sendOnlinePackets: s.sendOnlinePackets = !s.sendOnlinePackets
        case .sendUploadProgress: s.sendUploadProgress = !s.sendUploadProgress
        case .sendOfflinePacketAfterOnline: s.sendOfflinePacketAfterOnline = !s.sendOfflinePacketAfterOnline
        case .markReadAfterAction: s.markReadAfterAction = !s.markReadAfterAction
        case .useScheduledMessages: s.useScheduledMessages = !s.useScheduledMessages
        case .sendWithoutSound: s.sendWithoutSound = !s.sendWithoutSound
        case .saveDeletedMessages: s.saveDeletedMessages = !s.saveDeletedMessages
        case .saveMessagesHistory: s.saveMessagesHistory = !s.saveMessagesHistory
        case .saveForBots: s.saveForBots = !s.saveForBots
        case .localPremium: s.localPremium = !s.localPremium
        case .disableAds: s.disableAds = !s.disableAds
        }
        updateState { _ in AyuGramState.current() }
    })

    let signal = combineLatest(
        context.sharedContext.presentationData,
        statePromise.get()
    )
    |> deliverOnMainQueue
    |> map { presentationData, state -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("AyuGram Preferences"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: ayuGramEntries(state: state),
            style: .blocks,
            animateChanges: true
        )
        return (controllerState, (listState, arguments))
    }

    return ItemListController(context: context, state: signal)
}
