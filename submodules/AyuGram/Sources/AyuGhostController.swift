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

private struct AyuGhostState: Equatable {
    var sendReadMessages: Bool
    var sendReadStories: Bool
    var sendOnlinePackets: Bool
    var sendUploadProgress: Bool
    var sendOfflinePacketAfterOnline: Bool
    var markReadAfterAction: Bool
    var useScheduledMessages: Bool
    var sendWithoutSound: Bool

    static func current() -> AyuGhostState {
        let s = AyuSettings.shared
        return AyuGhostState(
            sendReadMessages: s.sendReadMessages,
            sendReadStories: s.sendReadStories,
            sendOnlinePackets: s.sendOnlinePackets,
            sendUploadProgress: s.sendUploadProgress,
            sendOfflinePacketAfterOnline: s.sendOfflinePacketAfterOnline,
            markReadAfterAction: s.markReadAfterAction,
            useScheduledMessages: s.useScheduledMessages,
            sendWithoutSound: s.sendWithoutSound
        )
    }
}

private final class AyuGhostArguments {
    let toggle: (AyuGhostSetting) -> Void
    var isRussian: Bool = false
    init(toggle: @escaping (AyuGhostSetting) -> Void) {
        self.toggle = toggle
    }
}

enum AyuGhostSetting {
    case sendReadMessages
    case sendReadStories
    case sendOnlinePackets
    case sendUploadProgress
    case sendOfflinePacketAfterOnline
    case markReadAfterAction
    case useScheduledMessages
    case sendWithoutSound
}

private enum AyuGhostSection: Int32 {
    case essentials
    case actions
}

private enum AyuGhostEntry: ItemListNodeEntry {
    case essentialsHeader
    case sendReadMessages(Bool)
    case sendReadStories(Bool)
    case sendOnlinePackets(Bool)
    case sendUploadProgress(Bool)
    case sendOfflinePacketAfterOnline(Bool)
    case essentialsFooter

    case actionsHeader
    case markReadAfterAction(Bool)
    case useScheduledMessages(Bool)
    case sendWithoutSound(Bool)

    var section: ItemListSectionId {
        switch self {
        case .essentialsHeader, .sendReadMessages, .sendReadStories,
             .sendOnlinePackets, .sendUploadProgress,
             .sendOfflinePacketAfterOnline, .essentialsFooter:
            return AyuGhostSection.essentials.rawValue
        case .actionsHeader, .markReadAfterAction,
             .useScheduledMessages, .sendWithoutSound:
            return AyuGhostSection.actions.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .essentialsHeader: return 0
        case .sendReadMessages: return 1
        case .sendReadStories: return 2
        case .sendOnlinePackets: return 3
        case .sendUploadProgress: return 4
        case .sendOfflinePacketAfterOnline: return 5
        case .essentialsFooter: return 6
        case .actionsHeader: return 7
        case .markReadAfterAction: return 8
        case .useScheduledMessages: return 9
        case .sendWithoutSound: return 10
        }
    }

    static func < (lhs: AyuGhostEntry, rhs: AyuGhostEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! AyuGhostArguments
        let ru = arguments.isRussian
        switch self {
        case .essentialsHeader:
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: ru ? "РЕЖИМ ПРИЗРАКА" : "GHOST ESSENTIALS",
                sectionId: self.section
            )
        case let .sendReadMessages(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: ru ? "Не читать сообщения" : "Don't Read Messages",
                value: !value,
                sectionId: self.section,
                style: .blocks,
                updated: { _ in arguments.toggle(.sendReadMessages) }
            )
        case let .sendReadStories(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: ru ? "Не читать истории" : "Don't Read Stories",
                value: !value,
                sectionId: self.section,
                style: .blocks,
                updated: { _ in arguments.toggle(.sendReadStories) }
            )
        case let .sendOnlinePackets(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: ru ? "Не отправлять статус онлайн" : "Don't Send Online Status",
                value: !value,
                sectionId: self.section,
                style: .blocks,
                updated: { _ in arguments.toggle(.sendOnlinePackets) }
            )
        case let .sendUploadProgress(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: ru ? "Не отправлять прогресс загрузки" : "Don't Send Upload Progress",
                value: !value,
                sectionId: self.section,
                style: .blocks,
                updated: { _ in arguments.toggle(.sendUploadProgress) }
            )
        case let .sendOfflinePacketAfterOnline(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: ru ? "Отправлять оффлайн после онлайна" : "Send Offline After Online",
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { _ in arguments.toggle(.sendOfflinePacketAfterOnline) }
            )
        case .essentialsFooter:
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain(ru ? "Режим призрака скрывает вашу онлайн-активность от других." : "Ghost mode hides your online activity from others."),
                sectionId: self.section
            )
        case .actionsHeader:
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: ru ? "ДЕЙСТВИЯ" : "ACTIONS",
                sectionId: self.section
            )
        case let .markReadAfterAction(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: ru ? "Отмечать прочитанным после действия" : "Mark Read After Action",
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { _ in arguments.toggle(.markReadAfterAction) }
            )
        case let .useScheduledMessages(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: ru ? "Использовать отложенные сообщения" : "Use Scheduled Messages",
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { _ in arguments.toggle(.useScheduledMessages) }
            )
        case let .sendWithoutSound(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: ru ? "Отправлять без звука" : "Send Without Sound",
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { _ in arguments.toggle(.sendWithoutSound) }
            )
        }
    }
}

private func ghostEntries(state: AyuGhostState) -> [AyuGhostEntry] {
    return [
        .essentialsHeader,
        .sendReadMessages(state.sendReadMessages),
        .sendReadStories(state.sendReadStories),
        .sendOnlinePackets(state.sendOnlinePackets),
        .sendUploadProgress(state.sendUploadProgress),
        .sendOfflinePacketAfterOnline(state.sendOfflinePacketAfterOnline),
        .essentialsFooter,
        .actionsHeader,
        .markReadAfterAction(state.markReadAfterAction),
        .useScheduledMessages(state.useScheduledMessages),
        .sendWithoutSound(state.sendWithoutSound),
    ]
}

public func ayuGhostController(context: AccountContext) -> ViewController {
    let statePromise = ValuePromise(AyuGhostState.current(), ignoreRepeated: true)
    let stateValue = Atomic(value: AyuGhostState.current())

    let updateState: ((AyuGhostState) -> AyuGhostState) -> Void = { f in
        statePromise.set(stateValue.modify { f($0) })
    }

    let arguments = AyuGhostArguments(toggle: { setting in
        let s = AyuSettings.shared
        switch setting {
        case .sendReadMessages:
            s.sendReadMessages = !s.sendReadMessages
        case .sendReadStories:
            s.sendReadStories = !s.sendReadStories
        case .sendOnlinePackets:
            s.sendOnlinePackets = !s.sendOnlinePackets
        case .sendUploadProgress:
            s.sendUploadProgress = !s.sendUploadProgress
        case .sendOfflinePacketAfterOnline:
            s.sendOfflinePacketAfterOnline = !s.sendOfflinePacketAfterOnline
        case .markReadAfterAction:
            s.markReadAfterAction = !s.markReadAfterAction
        case .useScheduledMessages:
            s.useScheduledMessages = !s.useScheduledMessages
        case .sendWithoutSound:
            s.sendWithoutSound = !s.sendWithoutSound
        }
        updateState { _ in AyuGhostState.current() }
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
            title: .text("AyuGram"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: ghostEntries(state: state),
            style: .blocks,
            animateChanges: true
        )
        return (controllerState, (listState, arguments))
    }

    return ItemListController(context: context, state: signal)
}
