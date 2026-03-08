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
import Postbox
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext
import AyuGramCore

private struct AyuEditHistoryState: Equatable {
    var entries: [AyuMessageEditEntry]
}

private enum AyuEditHistorySection: Int32 {
    case history
}

private enum AyuEditHistoryEntry: ItemListNodeEntry {
    case versionEntry(index: Int32, text: String, date: String)

    var section: ItemListSectionId {
        return AyuEditHistorySection.history.rawValue
    }

    var stableId: Int32 {
        switch self {
        case let .versionEntry(index, _, _): return index
        }
    }

    static func < (lhs: AyuEditHistoryEntry, rhs: AyuEditHistoryEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        switch self {
        case let .versionEntry(_, text, date):
            return ItemListTextItem(presentationData: presentationData, text: .markdown("**\(date)**\n\(text)"), sectionId: self.section)
        }
    }
}

private func editHistoryEntries(state: AyuEditHistoryState, presentationData: PresentationData) -> [AyuEditHistoryEntry] {
    return state.entries.enumerated().map { idx, entry in
        let date = Date(timeIntervalSince1970: TimeInterval(entry.timestamp))
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let dateStr = formatter.string(from: date)
        return .versionEntry(index: Int32(idx), text: entry.text, date: dateStr)
    }
}

public func ayuEditHistoryController(context: AccountContext, message: Message) -> ViewController {
    var history: [AyuMessageEditEntry] = []
    for attr in message.attributes {
        if let attr = attr as? AyuMessageEditHistoryAttribute {
            history = attr.history.reversed()
            break
        }
    }

    let state = AyuEditHistoryState(entries: history)
    let statePromise = ValuePromise(state, ignoreRepeated: true)

    let signal = combineLatest(
        context.sharedContext.presentationData,
        statePromise.get()
    )
    |> deliverOnMainQueue
    |> map { presentationData, state -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Edit History"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: editHistoryEntries(state: state, presentationData: presentationData),
            style: .blocks,
            animateChanges: false
        )
        return (controllerState, (listState, ()))
    }

    return ItemListController(context: context, state: signal)
}
