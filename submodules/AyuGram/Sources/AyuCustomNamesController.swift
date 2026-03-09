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

private struct AyuCustomNamesEntry {
    let peerId: String
    let name: String
}

private struct AyuCustomNamesState: Equatable {
    var names: [String: String]

    static func == (lhs: AyuCustomNamesState, rhs: AyuCustomNamesState) -> Bool {
        return lhs.names == rhs.names
    }

    static func current() -> AyuCustomNamesState {
        return AyuCustomNamesState(names: AyuSettings.shared.customPeerNames)
    }

    var sorted: [AyuCustomNamesEntry] {
        return names
            .map { AyuCustomNamesEntry(peerId: $0.key, name: $0.value) }
            .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }
}

private final class AyuCustomNamesArguments {
    let deleteName: (String) -> Void
    var isRussian: Bool = false

    init(deleteName: @escaping (String) -> Void) {
        self.deleteName = deleteName
    }
}

private enum AyuCustomNamesSection: Int32 {
    case list
    case empty
}

private enum AyuCustomNamesListEntry: ItemListNodeEntry {
    case emptyState
    case nameItem(Int, String, String)

    var section: ItemListSectionId {
        switch self {
        case .emptyState: return AyuCustomNamesSection.empty.rawValue
        case .nameItem: return AyuCustomNamesSection.list.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .emptyState: return 0
        case let .nameItem(index, _, _): return Int32(index + 1)
        }
    }

    static func < (lhs: AyuCustomNamesListEntry, rhs: AyuCustomNamesListEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! AyuCustomNamesArguments
        let ru = arguments.isRussian
        switch self {
        case .emptyState:
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain(ru
                    ? "Нет псевдонимов. Удерживайте чат в списке и выберите «Псевдоним», чтобы задать имя."
                    : "No custom names set. Long-press a chat and choose \"Custom Name\" to set one."
                ),
                sectionId: self.section
            )
        case let .nameItem(_, peerId, name):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                icon: UIImage(systemName: "person.circle"),
                title: name,
                label: "ID: \(peerId)",
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .none,
                action: {},
                tag: nil
            )
        }
    }
}

private func customNamesEntries(state: AyuCustomNamesState) -> [AyuCustomNamesListEntry] {
    let sorted = state.sorted
    if sorted.isEmpty {
        return [.emptyState]
    }
    return sorted.enumerated().map { .nameItem($0.offset, $0.element.peerId, $0.element.name) }
}

public func ayuCustomNamesController(context: AccountContext) -> ViewController {
    let statePromise = ValuePromise(AyuCustomNamesState.current(), ignoreRepeated: true)
    let stateValue = Atomic(value: AyuCustomNamesState.current())

    let updateState: ((AyuCustomNamesState) -> AyuCustomNamesState) -> Void = { f in
        statePromise.set(stateValue.modify { f($0) })
    }

    let arguments = AyuCustomNamesArguments(
        deleteName: { peerId in
            if let id = Int64(peerId) {
                AyuSettings.shared.setCustomName(nil, for: id)
            }
            updateState { _ in AyuCustomNamesState.current() }
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
            title: .text(isRussian ? "Псевдонимы" : "Custom Names"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: customNamesEntries(state: state),
            style: .blocks,
            animateChanges: true
        )
        return (controllerState, (listState, arguments))
    }

    return ItemListController(context: context, state: signal)
}
