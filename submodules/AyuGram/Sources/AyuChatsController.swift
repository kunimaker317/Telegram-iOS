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

private struct AyuChatsState: Equatable {
    var disableNotificationsDelay: Bool
    var stickerConfirmation: Bool
    var gifConfirmation: Bool
    var voiceConfirmation: Bool
    var recentStickersCount: Int

    static func current() -> AyuChatsState {
        let s = AyuSettings.shared
        return AyuChatsState(
            disableNotificationsDelay: s.disableNotificationsDelay,
            stickerConfirmation: s.stickerConfirmation,
            gifConfirmation: s.gifConfirmation,
            voiceConfirmation: s.voiceConfirmation,
            recentStickersCount: s.recentStickersCount
        )
    }
}

private final class AyuChatsArguments {
    let toggle: (AyuChatsSetting) -> Void
    var isRussian: Bool = false
    init(toggle: @escaping (AyuChatsSetting) -> Void) {
        self.toggle = toggle
    }
}

enum AyuChatsSetting {
    case disableNotificationsDelay
    case stickerConfirmation
    case gifConfirmation
    case voiceConfirmation
}

private enum AyuChatsSection: Int32 {
    case notifications
    case confirmation
}

private enum AyuChatsEntry: ItemListNodeEntry {
    case notificationsHeader
    case disableNotificationsDelay(Bool)
    case notificationsFooter

    case confirmationHeader
    case stickerConfirmation(Bool)
    case gifConfirmation(Bool)
    case voiceConfirmation(Bool)

    var section: ItemListSectionId {
        switch self {
        case .notificationsHeader, .disableNotificationsDelay, .notificationsFooter:
            return AyuChatsSection.notifications.rawValue
        case .confirmationHeader, .stickerConfirmation, .gifConfirmation, .voiceConfirmation:
            return AyuChatsSection.confirmation.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .notificationsHeader: return 0
        case .disableNotificationsDelay: return 1
        case .notificationsFooter: return 2
        case .confirmationHeader: return 3
        case .stickerConfirmation: return 4
        case .gifConfirmation: return 5
        case .voiceConfirmation: return 6
        }
    }

    static func < (lhs: AyuChatsEntry, rhs: AyuChatsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! AyuChatsArguments
        let ru = arguments.isRussian
        switch self {
        case .notificationsHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: ru ? "УВЕДОМЛЕНИЯ" : "NOTIFICATIONS", sectionId: self.section)
        case let .disableNotificationsDelay(value):
            return ItemListSwitchItem(presentationData: presentationData, title: ru ? "Отключить задержку уведомлений" : "Disable Notifications Delay", value: value, sectionId: self.section, style: .blocks, updated: { _ in arguments.toggle(.disableNotificationsDelay) })
        case .notificationsFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain(ru ? "Отправлять уведомления немедленно без стандартной задержки." : "Send notifications immediately without the standard delay."), sectionId: self.section)
        case .confirmationHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: ru ? "ПОДТВЕРЖДЕНИЕ ОТПРАВКИ" : "SEND CONFIRMATION", sectionId: self.section)
        case let .stickerConfirmation(value):
            return ItemListSwitchItem(presentationData: presentationData, title: ru ? "Подтверждать отправку стикера" : "Confirm Before Sending Sticker", value: value, sectionId: self.section, style: .blocks, updated: { _ in arguments.toggle(.stickerConfirmation) })
        case let .gifConfirmation(value):
            return ItemListSwitchItem(presentationData: presentationData, title: ru ? "Подтверждать отправку GIF" : "Confirm Before Sending GIF", value: value, sectionId: self.section, style: .blocks, updated: { _ in arguments.toggle(.gifConfirmation) })
        case let .voiceConfirmation(value):
            return ItemListSwitchItem(presentationData: presentationData, title: ru ? "Подтверждать отправку голосового" : "Confirm Before Sending Voice", value: value, sectionId: self.section, style: .blocks, updated: { _ in arguments.toggle(.voiceConfirmation) })
        }
    }
}

private func chatsEntries(state: AyuChatsState) -> [AyuChatsEntry] {
    return [
        .notificationsHeader,
        .disableNotificationsDelay(state.disableNotificationsDelay),
        .notificationsFooter,
        .confirmationHeader,
        .stickerConfirmation(state.stickerConfirmation),
        .gifConfirmation(state.gifConfirmation),
        .voiceConfirmation(state.voiceConfirmation),
    ]
}

public func ayuChatsController(context: AccountContext) -> ViewController {
    let statePromise = ValuePromise(AyuChatsState.current(), ignoreRepeated: true)
    let stateValue = Atomic(value: AyuChatsState.current())

    let updateState: ((AyuChatsState) -> AyuChatsState) -> Void = { f in
        statePromise.set(stateValue.modify { f($0) })
    }

    let arguments = AyuChatsArguments(toggle: { setting in
        let s = AyuSettings.shared
        switch setting {
        case .disableNotificationsDelay: s.disableNotificationsDelay = !s.disableNotificationsDelay
        case .stickerConfirmation: s.stickerConfirmation = !s.stickerConfirmation
        case .gifConfirmation: s.gifConfirmation = !s.gifConfirmation
        case .voiceConfirmation: s.voiceConfirmation = !s.voiceConfirmation
        }
        updateState { _ in AyuChatsState.current() }
    })

    let signal = combineLatest(
        context.sharedContext.presentationData,
        statePromise.get()
    )
    |> deliverOnMainQueue
    |> map { presentationData, state -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let isRussian = presentationData.strings.baseLanguageCode == "ru"
        arguments.isRussian = isRussian
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(isRussian ? "Чаты" : "Chats"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: chatsEntries(state: state),
            style: .blocks,
            animateChanges: true
        )
        return (controllerState, (listState, arguments))
    }

    return ItemListController(context: context, state: signal)
}
