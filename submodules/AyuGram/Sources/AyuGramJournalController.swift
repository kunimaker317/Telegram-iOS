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

private enum AyuJournalSection: Int32 {
    case events
}

private enum AyuJournalEntry: ItemListNodeEntry {
    case empty
    case event(Int, AyuLogEvent)

    var section: ItemListSectionId {
        return AyuJournalSection.events.rawValue
    }

    var stableId: Int32 {
        switch self {
        case .empty: return 0
        case let .event(idx, _): return Int32(idx + 1)
        }
    }

    static func < (lhs: AyuJournalEntry, rhs: AyuJournalEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! AyuJournalArguments
        let ru = args.isRussian
        switch self {
        case .empty:
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain(ru ? "История пуста." : "No events yet. Deleted and edited messages will appear here."),
                sectionId: self.section
            )
        case let .event(_, event):
            let actionText: String
            switch event.type {
            case .deleted:
                actionText = ru ? "удалил(а)" : "deleted"
            case .edited:
                actionText = ru ? "изменил(а)" : "edited"
            }

            var body = "\(event.senderName) \(actionText)"
            if let text = event.messageText, !text.isEmpty {
                let preview = text.count > 60 ? String(text.prefix(60)) + "..." : text
                body += ": \"\(preview)\""
            }

            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: "\(event.chatName) — \(body)",
                label: event.formattedDate,
                sectionId: self.section,
                style: .blocks,
                action: {}
            )
        }
    }
}

private final class AyuJournalArguments {
    var isRussian: Bool = false
    init() {}
}

public func ayuGramJournalController(context: AccountContext) -> ViewController {
    let eventsPromise = ValuePromise<[AyuLogEvent]>(AyuNotificationLog.shared.allEvents(), ignoreRepeated: false)

    let arguments = AyuJournalArguments()

    let signal = combineLatest(
        context.sharedContext.presentationData,
        eventsPromise.get()
    )
    |> deliverOnMainQueue
    |> map { presentationData, events -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let isRussian = presentationData.strings.baseLanguageCode == "ru"
        arguments.isRussian = isRussian

        var entries: [AyuJournalEntry] = []
        if events.isEmpty {
            entries.append(.empty)
        } else {
            for (i, event) in events.enumerated() {
                entries.append(.event(i, event))
            }
        }

        let clearButton = ItemListNavigationButton(
            content: .text(isRussian ? "Очистить" : "Clear"),
            style: .regular,
            enabled: !events.isEmpty,
            action: {
                AyuNotificationLog.shared.clearAll()
                eventsPromise.set([])
            }
        )

        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(isRussian ? "Журнал AyuGram" : "AyuGram Journal"),
            leftNavigationButton: nil,
            rightNavigationButton: clearButton,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: entries,
            style: .blocks,
            animateChanges: true
        )
        return (controllerState, (listState, arguments))
    }

    return ItemListController(context: context, state: signal)
}
