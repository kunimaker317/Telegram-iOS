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

private final class AyuGramSettingsArguments {
    let openGhost: () -> Void
    let openGeneral: () -> Void
    let openAppearance: () -> Void
    let openChats: () -> Void
    let openOther: () -> Void
    let openChannel: () -> Void
    let openChat: () -> Void
    let openDocs: () -> Void

    init(
        openGhost: @escaping () -> Void,
        openGeneral: @escaping () -> Void,
        openAppearance: @escaping () -> Void,
        openChats: @escaping () -> Void,
        openOther: @escaping () -> Void,
        openChannel: @escaping () -> Void,
        openChat: @escaping () -> Void,
        openDocs: @escaping () -> Void
    ) {
        self.openGhost = openGhost
        self.openGeneral = openGeneral
        self.openAppearance = openAppearance
        self.openChats = openChats
        self.openOther = openOther
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
    case chats
    case other
    case linksHeader
    case channelLink
    case chatLink
    case docsLink

    var section: ItemListSectionId {
        switch self {
        case .headerInfo:
            return AyuGramSection.header.rawValue
        case .ghost, .general, .appearance, .chats, .other:
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
        case .chats: return 4
        case .other: return 5
        case .linksHeader: return 6
        case .channelLink: return 7
        case .chatLink: return 8
        case .docsLink: return 9
        }
    }

    static func < (lhs: AyuGramEntry, rhs: AyuGramEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! AyuGramSettingsArguments
        switch self {
        case let .headerInfo(version):
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain("AyuGram iOS \(version)\nBased on Telegram"),
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
                title: "General",
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
                title: "Appearance",
                label: "",
                sectionId: self.section,
                style: .blocks,
                action: {
                    arguments.openAppearance()
                }
            )
        case .chats:
            return ItemListDisclosureItem(
                presentationData: presentationData,
                icon: UIImage(systemName: "bubble.left.and.bubble.right"),
                title: "Chats",
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
                title: "Other",
                label: "",
                sectionId: self.section,
                style: .blocks,
                action: {
                    arguments.openOther()
                }
            )
        case .linksHeader:
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: "LINKS",
                sectionId: self.section
            )
        case .channelLink:
            return ItemListDisclosureItem(
                presentationData: presentationData,
                icon: UIImage(systemName: "megaphone"),
                title: "Channel",
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
                title: "Chat",
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
                title: "Documentation",
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
    entries.append(.chats)
    entries.append(.other)
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
            pushControllerImpl?(ayuGramController(context: context))
        },
        openGeneral: {
            pushControllerImpl?(ayuGeneralController(context: context))
        },
        openAppearance: {
            pushControllerImpl?(ayuAppearanceController(context: context))
        },
        openChats: {
            pushControllerImpl?(ayuChatsController(context: context))
        },
        openOther: {
            pushControllerImpl?(ayuOtherController(context: context))
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
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("AyuGram"),
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
