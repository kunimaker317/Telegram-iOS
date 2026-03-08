// This is the source code of AyuGram for iOS.
//
// We do not and cannot prevent the use of our code,
// but be respectful and credit the original author.
//
// Copyright @Radolyn, 2025

import Foundation
import Postbox

public struct AyuMessageEditEntry: PostboxCoding, Equatable {
    public let text: String
    public let timestamp: Int32

    public init(text: String, timestamp: Int32) {
        self.text = text
        self.timestamp = timestamp
    }

    public init(decoder: PostboxDecoder) {
        self.text = decoder.decodeStringForKey("t", orElse: "")
        self.timestamp = decoder.decodeInt32ForKey("d", orElse: 0)
    }

    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeString(self.text, forKey: "t")
        encoder.encodeInt32(self.timestamp, forKey: "d")
    }
}

public final class AyuMessageEditHistoryAttribute: MessageAttribute {
    public let history: [AyuMessageEditEntry]

    public init(history: [AyuMessageEditEntry]) {
        self.history = history
    }

    required public init(decoder: PostboxDecoder) {
        self.history = decoder.decodeObjectArrayWithDecoderForKey("h") as [AyuMessageEditEntry]
    }

    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeObjectArray(self.history, forKey: "h")
    }
}
