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
import SafariServices
import SettingsUI

private final class AyuGramSettingsArguments {
    let openGhost: () -> Void
    let openGeneral: () -> Void
    let openAppearance: () -> Void
    let openAppIcons: () -> Void
    let openChats: () -> Void
    let openOther: () -> Void
    let openJournal: () -> Void
    let openChannel: () -> Void
    let openChat: () -> Void
    let openDocs: () -> Void
    var isRussian: Bool = false

    init(
        openGhost: @escaping () -> Void,
        openGeneral: @escaping () -> Void,
        openAppearance: @escaping () -> Void,
        openAppIcons: @escaping () -> Void,
        openChats: @escaping () -> Void,
        openOther: @escaping () -> Void,
        openJournal: @escaping () -> Void,
        openChannel: @escaping () -> Void,
        openChat: @escaping () -> Void,
        openDocs: @escaping () -> Void
    ) {
        self.openGhost = openGhost
        self.openGeneral = openGeneral
        self.openAppearance = openAppearance
        self.openAppIcons = openAppIcons
        self.openChats = openChats
        self.openOther = openOther
        self.openJournal = openJournal
        self.openChannel = openChannel
        self.openChat = openChat
        self.openDocs = openDocs
    }
}

private enum AyuGramSection: Int32 {
    case header
    case categories
    case links
}

private enum AyuGramEntry: ItemListNodeEntry {
    case headerInfo(String)
    case ghost
    case general
    case appearance
    case appIcons
    case chats
    case other
    case journal
    case linksHeader
    case channelLink
    case chatLink
    case docsLink

    var section: ItemListSectionId {
        switch self {
        case .headerInfo:
            return AyuGramSection.header.rawValue
        case .ghost, .general, .appearance, .appIcons, .chats, .other:
            return AyuGramSection.categories.rawValue
        case .journal:
            return AyuGramSection.categories.rawValue
        case .linksHeader, .channelLink, .chatLink, .docsLink:
            return AyuGramSection.links.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .headerInfo: return 0
        case .ghost: return 1
        case .general: return 2
        case .appearance: return 3
        case .appIcons: return 4
        case .chats: return 5
        case .other: return 6
        case .journal: return 11
        case .linksHeader: return 7
        case .channelLink: return 8
        case .chatLink: return 9
        case .docsLink: return 10
        }
    }

    static func < (lhs: AyuGramEntry, rhs: AyuGramEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! AyuGramSettingsArguments
        let ru = arguments.isRussian
        switch self {
        case let .headerInfo(version):
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain("AyuGram iOS \(version)\n\(ru ? "На основе Telegram" : "Based on Telegram")"),
                sectionId: self.section
            )
        case .ghost:
            return ItemListDisclosureItem(
                presentationData: presentationData,
                icon: UIImage(systemName: "eye.slash"),
                title: "AyuGram",
                label: "",
                sectionId: self.section,
                style: .blocks,
                action: {
                    arguments.openGhost()
                }
            )
        case .general:
            return ItemListDisclosureItem(
                presentationData: presentationData,
                icon: UIImage(systemName: "gearshape"),
                title: ru ? "Основное" : "General",
                label: "",
                sectionId: self.section,
                style: .blocks,
                action: {
                    arguments.openGeneral()
                }
            )
        case .appearance:
            return ItemListDisclosureItem(
                presentationData: presentationData,
                icon: UIImage(systemName: "paintpalette"),
                title: ru ? "Внешний вид" : "Appearance",
                label: "",
                sectionId: self.section,
                style: .blocks,
                action: {
                    arguments.openAppearance()
                }
            )
        case .appIcons:
            return ItemListDisclosureItem(
                presentationData: presentationData,
                icon: UIImage(systemName: "app.badge"),
                title: ru ? "Иконка" : "App Icon",
                label: "",
                sectionId: self.section,
                style: .blocks,
                action: {
                    arguments.openAppIcons()
                }
            )
        case .chats:
            return ItemListDisclosureItem(
                presentationData: presentationData,
                icon: UIImage(systemName: "bubble.left.and.bubble.right"),
                title: ru ? "Чаты" : "Chats",
                label: "",
                sectionId: self.section,
                style: .blocks,
                action: {
                    arguments.openChats()
                }
            )
        case .other:
            return ItemListDisclosureItem(
                presentationData: presentationData,
                icon: UIImage(systemName: "ellipsis.circle"),
                title: ru ? "Другое" : "Other",
                label: "",
                sectionId: self.section,
                style: .blocks,
                action: {
                    arguments.openOther()
                }
            )
        case .journal:
            return ItemListDisclosureItem(
                presentationData: presentationData,
                icon: UIImage(systemName: "list.bullet.clipboard"),
                title: ru ? "Журнал" : "Journal",
                label: "",
                sectionId: self.section,
                style: .blocks,
                action: {
                    arguments.openJournal()
                }
            )
        case .linksHeader:
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: ru ? "ССЫЛКИ" : "LINKS",
                sectionId: self.section
            )
        case .channelLink:
            return ItemListDisclosureItem(
                presentationData: presentationData,
                icon: UIImage(systemName: "megaphone"),
                title: ru ? "Канал" : "Channel",
                label: "@ayugram",
                sectionId: self.section,
                style: .blocks,
                action: {
                    arguments.openChannel()
                }
            )
        case .chatLink:
            return ItemListDisclosureItem(
                presentationData: presentationData,
                icon: UIImage(systemName: "bubble.left.and.bubble.right"),
                title: ru ? "Чат" : "Chat",
                label: "@ayugramchat",
                sectionId: self.section,
                style: .blocks,
                action: {
                    arguments.openChat()
                }
            )
        case .docsLink:
            return ItemListDisclosureItem(
                presentationData: presentationData,
                icon: UIImage(systemName: "book"),
                title: ru ? "Документация" : "Documentation",
                label: "docs.ayugram.one",
                sectionId: self.section,
                style: .blocks,
                action: {
                    arguments.openDocs()
                }
            )
        }
    }
}

private func ayuGramEntries(presentationData: PresentationData) -> [AyuGramEntry] {
    var entries: [AyuGramEntry] = []
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    entries.append(.headerInfo(version))
    entries.append(.ghost)
    entries.append(.general)
    entries.append(.appearance)
    entries.append(.appIcons)
    entries.append(.chats)
    entries.append(.other)
    entries.append(.journal)
    entries.append(.linksHeader)
    entries.append(.channelLink)
    entries.append(.chatLink)
    entries.append(.docsLink)
    return entries
}

public func ayuGramSettingsController(context: AccountContext) -> ViewController {
    var pushControllerImpl: ((ViewController) -> Void)?
    var openUrlImpl: ((String) -> Void)?

    let arguments = AyuGramSettingsArguments(
        openGhost: {
            pushControllerImpl?(ayuGhostController(context: context))
        },
        openGeneral: {
            pushControllerImpl?(ayuGeneralController(context: context))
        },
        openAppearance: {
            pushControllerImpl?(ayuAppearanceController(context: context))
        },
        openAppIcons: {
            pushControllerImpl?(themeSettingsController(context: context))
        },
        openChats: {
            pushControllerImpl?(ayuChatsController(context: context))
        },
        openOther: {
            pushControllerImpl?(ayuOtherController(context: context))
        },
        openJournal: {
            pushControllerImpl?(ayuGramJournalController(context: context))
        },
        openChannel: {
            openUrlImpl?("https://t.me/ayugram")
        },
        openChat: {
            openUrlImpl?("https://t.me/ayugramchat")
        },
        openDocs: {
            openUrlImpl?("https://docs.ayugram.one/desktop/")
        }
    )

    let signal = context.sharedContext.presentationData
    |> deliverOnMainQueue
    |> map { presentationData -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let isRussian = presentationData.strings.baseLanguageCode == "ru"
        arguments.isRussian = isRussian
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text(isRussian ? "Настройки AyuGram" : "AyuGram Preferences"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: ayuGramEntries(presentationData: presentationData),
            style: .blocks,
            animateChanges: true
        )
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    pushControllerImpl = { [weak controller] c in
        controller?.push(c)
    }
    openUrlImpl = { [weak controller] url in
        guard let controller else { return }
        let safariController = SFSafariViewController(url: URL(string: url)!)
        controller.present(safariController, animated: true)
    }
    return controller
}
