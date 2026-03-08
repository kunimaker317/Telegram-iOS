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

private struct AyuAppearanceState: Equatable {
    var removeMessageTail: Bool
    var simpleQuotesAndReplies: Bool
    var adaptiveCoverColor: Bool
    var hideNotificationCounters: Bool
    var hideNotificationBadge: Bool
    var hideAllChatsFolder: Bool

    static func current() -> AyuAppearanceState {
        let s = AyuSettings.shared
        return AyuAppearanceState(
            removeMessageTail: s.removeMessageTail,
            simpleQuotesAndReplies: s.simpleQuotesAndReplies,
            adaptiveCoverColor: s.adaptiveCoverColor,
            hideNotificationCounters: s.hideNotificationCounters,
            hideNotificationBadge: s.hideNotificationBadge,
            hideAllChatsFolder: s.hideAllChatsFolder
        )
    }
}

private final class AyuAppearanceArguments {
    let toggle: (AyuAppearanceSetting) -> Void
    init(toggle: @escaping (AyuAppearanceSetting) -> Void) {
        self.toggle = toggle
    }
}

enum AyuAppearanceSetting {
    case removeMessageTail
    case simpleQuotesAndReplies
    case adaptiveCoverColor
    case hideNotificationCounters
    case hideNotificationBadge
    case hideAllChatsFolder
}

private enum AyuAppearanceSection: Int32 {
    case messages
    case notifications
    case chats
}

private enum AyuAppearanceEntry: ItemListNodeEntry {
    case messagesHeader
    case removeMessageTail(Bool)
    case simpleQuotesAndReplies(Bool)
    case adaptiveCoverColor(Bool)
    case messagesFooter

    case notificationsHeader
    case hideNotificationCounters(Bool)
    case hideNotificationBadge(Bool)

    case chatsHeader
    case hideAllChatsFolder(Bool)

    var section: ItemListSectionId {
        switch self {
        case .messagesHeader, .removeMessageTail, .simpleQuotesAndReplies, .adaptiveCoverColor, .messagesFooter:
            return AyuAppearanceSection.messages.rawValue
        case .notificationsHeader, .hideNotificationCounters, .hideNotificationBadge:
            return AyuAppearanceSection.notifications.rawValue
        case .chatsHeader, .hideAllChatsFolder:
            return AyuAppearanceSection.chats.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .messagesHeader: return 0
        case .removeMessageTail: return 1
        case .simpleQuotesAndReplies: return 2
        case .adaptiveCoverColor: return 3
        case .messagesFooter: return 4
        case .notificationsHeader: return 5
        case .hideNotificationCounters: return 6
        case .hideNotificationBadge: return 7
        case .chatsHeader: return 8
        case .hideAllChatsFolder: return 9
        }
    }

    static func < (lhs: AyuAppearanceEntry, rhs: AyuAppearanceEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! AyuAppearanceArguments
        switch self {
        case .messagesHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "MESSAGES", sectionId: self.section)
        case let .removeMessageTail(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Remove Message Tail", value: value, sectionId: self.section, style: .blocks, updated: { _ in arguments.toggle(.removeMessageTail) })
        case let .simpleQuotesAndReplies(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Simple Quotes & Replies", value: value, sectionId: self.section, style: .blocks, updated: { _ in arguments.toggle(.simpleQuotesAndReplies) })
        case let .adaptiveCoverColor(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Adaptive Cover Color", value: value, sectionId: self.section, style: .blocks, updated: { _ in arguments.toggle(.adaptiveCoverColor) })
        case .messagesFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain("Customize the look of messages."), sectionId: self.section)
        case .notificationsHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "NOTIFICATIONS", sectionId: self.section)
        case let .hideNotificationCounters(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Hide Notification Counters", value: value, sectionId: self.section, style: .blocks, updated: { _ in arguments.toggle(.hideNotificationCounters) })
        case let .hideNotificationBadge(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Hide App Badge", value: value, sectionId: self.section, style: .blocks, updated: { _ in arguments.toggle(.hideNotificationBadge) })
        case .chatsHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "CHATS", sectionId: self.section)
        case let .hideAllChatsFolder(value):
            return ItemListSwitchItem(presentationData: presentationData, title: "Hide \"All Chats\" Folder", value: value, sectionId: self.section, style: .blocks, updated: { _ in arguments.toggle(.hideAllChatsFolder) })
        }
    }
}

private func appearanceEntries(state: AyuAppearanceState) -> [AyuAppearanceEntry] {
    return [
        .messagesHeader,
        .removeMessageTail(state.removeMessageTail),
        .simpleQuotesAndReplies(state.simpleQuotesAndReplies),
        .adaptiveCoverColor(state.adaptiveCoverColor),
        .messagesFooter,
        .notificationsHeader,
        .hideNotificationCounters(state.hideNotificationCounters),
        .hideNotificationBadge(state.hideNotificationBadge),
        .chatsHeader,
        .hideAllChatsFolder(state.hideAllChatsFolder),
    ]
}

public func ayuAppearanceController(context: AccountContext) -> ViewController {
    let statePromise = ValuePromise(AyuAppearanceState.current(), ignoreRepeated: true)
    let stateValue = Atomic(value: AyuAppearanceState.current())

    let updateState: ((AyuAppearanceState) -> AyuAppearanceState) -> Void = { f in
        statePromise.set(stateValue.modify { f($0) })
    }

    let arguments = AyuAppearanceArguments(toggle: { setting in
        let s = AyuSettings.shared
        switch setting {
        case .removeMessageTail: s.removeMessageTail = !s.removeMessageTail
        case .simpleQuotesAndReplies: s.simpleQuotesAndReplies = !s.simpleQuotesAndReplies
        case .adaptiveCoverColor: s.adaptiveCoverColor = !s.adaptiveCoverColor
        case .hideNotificationCounters: s.hideNotificationCounters = !s.hideNotificationCounters
        case .hideNotificationBadge: s.hideNotificationBadge = !s.hideNotificationBadge
        case .hideAllChatsFolder: s.hideAllChatsFolder = !s.hideAllChatsFolder
        }
        updateState { _ in AyuAppearanceState.current() }
    })

    let signal = combineLatest(
        context.sharedContext.presentationData,
        statePromise.get()
    )
    |> deliverOnMainQueue
    |> map { presentationData, state -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Appearance"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: appearanceEntries(state: state),
            style: .blocks,
            animateChanges: true
        )
        return (controllerState, (listState, arguments))
    }

    return ItemListController(context: context, state: signal)
}
