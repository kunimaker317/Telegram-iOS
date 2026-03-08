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

private struct AyuOtherState: Equatable {
    var translationProvider: String
    var crashReporting: Bool

    static func current() -> AyuOtherState {
        let s = AyuSettings.shared
        return AyuOtherState(
            translationProvider: s.translationProvider,
            crashReporting: s.crashReporting
        )
    }
}

private final class AyuOtherArguments {
    let setTranslationProvider: (String) -> Void
    let toggleCrashReporting: () -> Void
    var isRussian: Bool = false
    init(
        setTranslationProvider: @escaping (String) -> Void,
        toggleCrashReporting: @escaping () -> Void
    ) {
        self.setTranslationProvider = setTranslationProvider
        self.toggleCrashReporting = toggleCrashReporting
    }
}

private enum AyuOtherSection: Int32 {
    case translation
    case reporting
}

private enum AyuOtherEntry: ItemListNodeEntry {
    case translationHeader
    case translationProvider(String)

    case reportingHeader
    case crashReporting(Bool)
    case reportingFooter

    var section: ItemListSectionId {
        switch self {
        case .translationHeader, .translationProvider:
            return AyuOtherSection.translation.rawValue
        case .reportingHeader, .crashReporting, .reportingFooter:
            return AyuOtherSection.reporting.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .translationHeader: return 0
        case .translationProvider: return 1
        case .reportingHeader: return 2
        case .crashReporting: return 3
        case .reportingFooter: return 4
        }
    }

    static func < (lhs: AyuOtherEntry, rhs: AyuOtherEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! AyuOtherArguments
        let ru = arguments.isRussian
        switch self {
        case .translationHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: ru ? "ПЕРЕВОД" : "TRANSLATION", sectionId: self.section)
        case let .translationProvider(value):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: ru ? "Провайдер перевода" : "Translation Provider",
                label: value,
                sectionId: self.section,
                style: .blocks,
                action: {
                    let next = value == "Google" ? "Yandex" : "Google"
                    arguments.setTranslationProvider(next)
                }
            )
        case .reportingHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: ru ? "ОТЧЁТЫ" : "REPORTING", sectionId: self.section)
        case let .crashReporting(value):
            return ItemListSwitchItem(presentationData: presentationData, title: ru ? "Отчёты об ошибках" : "Crash Reporting", value: value, sectionId: self.section, style: .blocks, updated: { _ in arguments.toggleCrashReporting() })
        case .reportingFooter:
            return ItemListTextItem(presentationData: presentationData, text: .plain(ru ? "Помогите улучшить AyuGram, отправляя анонимные отчёты об ошибках." : "Help improve AyuGram by sending anonymous crash reports."), sectionId: self.section)
        }
    }
}

private func otherEntries(state: AyuOtherState) -> [AyuOtherEntry] {
    return [
        .translationHeader,
        .translationProvider(state.translationProvider),
        .reportingHeader,
        .crashReporting(state.crashReporting),
        .reportingFooter,
    ]
}

public func ayuOtherController(context: AccountContext) -> ViewController {
    let statePromise = ValuePromise(AyuOtherState.current(), ignoreRepeated: true)
    let stateValue = Atomic(value: AyuOtherState.current())

    let updateState: ((AyuOtherState) -> AyuOtherState) -> Void = { f in
        statePromise.set(stateValue.modify { f($0) })
    }

    let arguments = AyuOtherArguments(
        setTranslationProvider: { value in
            AyuSettings.shared.translationProvider = value
            updateState { _ in AyuOtherState.current() }
        },
        toggleCrashReporting: {
            AyuSettings.shared.crashReporting = !AyuSettings.shared.crashReporting
            updateState { _ in AyuOtherState.current() }
        }
    )

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
            title: .text(isRussian ? "Другое" : "Other"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: otherEntries(state: state),
            style: .blocks,
            animateChanges: true
        )
        return (controllerState, (listState, arguments))
    }

    return ItemListController(context: context, state: signal)
}
