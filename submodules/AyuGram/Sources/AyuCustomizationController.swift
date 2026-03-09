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

private struct AyuCustomizationState: Equatable {
    var customTypingText: String
    var customRecordingText: String
    var customUploadingText: String
    var customPeerNamesCount: Int

    static func current() -> AyuCustomizationState {
        let s = AyuSettings.shared
        return AyuCustomizationState(
            customTypingText: s.customTypingText,
            customRecordingText: s.customRecordingText,
            customUploadingText: s.customUploadingText,
            customPeerNamesCount: s.customPeerNames.count
        )
    }
}

private final class AyuCustomizationArguments {
    let openCustomNames: () -> Void
    let editTypingText: () -> Void
    let editRecordingText: () -> Void
    let editUploadingText: () -> Void
    var isRussian: Bool = false

    init(
        openCustomNames: @escaping () -> Void,
        editTypingText: @escaping () -> Void,
        editRecordingText: @escaping () -> Void,
        editUploadingText: @escaping () -> Void
    ) {
        self.openCustomNames = openCustomNames
        self.editTypingText = editTypingText
        self.editRecordingText = editRecordingText
        self.editUploadingText = editUploadingText
    }
}

private enum AyuCustomizationSection: Int32 {
    case names
    case interaction
}

private enum AyuCustomizationEntry: ItemListNodeEntry {
    case namesHeader
    case customNames(Int)
    case namesFooter

    case interactionHeader
    case typingText(String)
    case recordingText(String)
    case uploadingText(String)
    case interactionFooter

    var section: ItemListSectionId {
        switch self {
        case .namesHeader, .customNames, .namesFooter:
            return AyuCustomizationSection.names.rawValue
        case .interactionHeader, .typingText, .recordingText, .uploadingText, .interactionFooter:
            return AyuCustomizationSection.interaction.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .namesHeader: return 0
        case .customNames: return 1
        case .namesFooter: return 2
        case .interactionHeader: return 3
        case .typingText: return 4
        case .recordingText: return 5
        case .uploadingText: return 6
        case .interactionFooter: return 7
        }
    }

    static func < (lhs: AyuCustomizationEntry, rhs: AyuCustomizationEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! AyuCustomizationArguments
        let ru = arguments.isRussian
        switch self {
        case .namesHeader:
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: ru ? "ПСЕВДОНИМЫ КОНТАКТОВ" : "CONTACT ALIASES",
                sectionId: self.section
            )
        case let .customNames(count):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                icon: UIImage(systemName: "person.text.rectangle"),
                title: ru ? "Псевдонимы" : "Custom Names",
                label: count > 0 ? "\(count)" : "",
                sectionId: self.section,
                style: .blocks,
                action: {
                    arguments.openCustomNames()
                }
            )
        case .namesFooter:
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain(ru
                    ? "Задайте псевдоним для любого контакта — он будет отображаться вместо настоящего имени во всём приложении."
                    : "Set a custom display name for any contact. It will be shown instead of their real name throughout the app."
                ),
                sectionId: self.section
            )
        case .interactionHeader:
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: ru ? "СТАТУСЫ АКТИВНОСТИ" : "ACTIVITY STATUSES",
                sectionId: self.section
            )
        case let .typingText(value):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                icon: UIImage(systemName: "keyboard"),
                title: ru ? "Текст «печатает»" : "Typing text",
                label: value.isEmpty ? (ru ? "по умолчанию" : "default") : value,
                sectionId: self.section,
                style: .blocks,
                action: {
                    arguments.editTypingText()
                }
            )
        case let .recordingText(value):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                icon: UIImage(systemName: "mic"),
                title: ru ? "Текст «записывает»" : "Recording text",
                label: value.isEmpty ? (ru ? "по умолчанию" : "default") : value,
                sectionId: self.section,
                style: .blocks,
                action: {
                    arguments.editRecordingText()
                }
            )
        case let .uploadingText(value):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                icon: UIImage(systemName: "arrow.up.circle"),
                title: ru ? "Текст «загружает»" : "Uploading text",
                label: value.isEmpty ? (ru ? "по умолчанию" : "default") : value,
                sectionId: self.section,
                style: .blocks,
                action: {
                    arguments.editUploadingText()
                }
            )
        case .interactionFooter:
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain(ru
                    ? "Замените стандартные тексты активности на свои. Оставьте пустым, чтобы использовать значение по умолчанию."
                    : "Replace default activity status texts with your own. Leave empty to use the default."
                ),
                sectionId: self.section
            )
        }
    }
}

private func customizationEntries(state: AyuCustomizationState) -> [AyuCustomizationEntry] {
    return [
        .namesHeader,
        .customNames(state.customPeerNamesCount),
        .namesFooter,
        .interactionHeader,
        .typingText(state.customTypingText),
        .recordingText(state.customRecordingText),
        .uploadingText(state.customUploadingText),
        .interactionFooter,
    ]
}


public func ayuCustomizationController(context: AccountContext) -> ViewController {
    let statePromise = ValuePromise(AyuCustomizationState.current(), ignoreRepeated: true)
    let stateValue = Atomic(value: AyuCustomizationState.current())

    let updateState: ((AyuCustomizationState) -> AyuCustomizationState) -> Void = { f in
        statePromise.set(stateValue.modify { f($0) })
    }

    var pushControllerImpl: ((ViewController) -> Void)?
    var presentAlertImpl: ((String, String, String, @escaping (String) -> Void) -> Void)?

    let arguments = AyuCustomizationArguments(
        openCustomNames: {
            pushControllerImpl?(ayuCustomNamesController(context: context))
        },
        editTypingText: {
            let current = AyuSettings.shared.customTypingText
            let isRu = context.sharedContext.currentPresentationData.with { $0 }.strings.baseLanguageCode == "ru"
            presentAlertImpl?(
                isRu ? "Текст «печатает»" : "Typing text",
                isRu ? "Введите текст или оставьте пустым" : "Enter text or leave empty for default",
                current,
                { newValue in
                    AyuSettings.shared.customTypingText = newValue
                    updateState { _ in AyuCustomizationState.current() }
                }
            )
        },
        editRecordingText: {
            let current = AyuSettings.shared.customRecordingText
            let isRu = context.sharedContext.currentPresentationData.with { $0 }.strings.baseLanguageCode == "ru"
            presentAlertImpl?(
                isRu ? "Текст «записывает»" : "Recording text",
                isRu ? "Введите текст или оставьте пустым" : "Enter text or leave empty for default",
                current,
                { newValue in
                    AyuSettings.shared.customRecordingText = newValue
                    updateState { _ in AyuCustomizationState.current() }
                }
            )
        },
        editUploadingText: {
            let current = AyuSettings.shared.customUploadingText
            let isRu = context.sharedContext.currentPresentationData.with { $0 }.strings.baseLanguageCode == "ru"
            presentAlertImpl?(
                isRu ? "Текст «загружает»" : "Uploading text",
                isRu ? "Введите текст или оставьте пустым" : "Enter text or leave empty for default",
                current,
                { newValue in
                    AyuSettings.shared.customUploadingText = newValue
                    updateState { _ in AyuCustomizationState.current() }
                }
            )
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
            title: .text(isRussian ? "Кастомизация" : "Customization"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: customizationEntries(state: state),
            style: .blocks,
            animateChanges: true
        )
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    pushControllerImpl = { [weak controller] c in
        controller?.push(c)
    }
    presentAlertImpl = { [weak controller] title, placeholder, current, completion in
        guard let controller = controller else { return }
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        let alertController = UIAlertController(title: title, message: placeholder, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.text = current
            textField.clearButtonMode = .whileEditing
        }
        alertController.addAction(UIAlertAction(title: presentationData.strings.Common_Cancel, style: .cancel))
        alertController.addAction(UIAlertAction(title: presentationData.strings.Common_Done, style: .default) { _ in
            let value = alertController.textFields?.first?.text ?? ""
            completion(value)
        })
        controller.present(alertController, animated: true)
    }
    return controller
}
