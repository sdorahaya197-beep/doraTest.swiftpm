import SwiftData
import Foundation

@Model
class Race {
    var name: String
    var date: Date
    var venue: String
    @Relationship(deleteRule: .cascade) var horses: [Horse] = []

    init(name: String = "", date: Date = .now, venue: String = "") {
        self.name = name
        self.date = date
        self.venue = venue
    }

    var displayName: String {
        name.isEmpty ? "無名レース" : name
    }
}

@Model
class Horse {
    var name: String
    var mark: String
    var memo: String
    var result: String
    var createdAt: Date

    init(name: String, mark: String = "▲", memo: String = "", result: String = "") {
        self.name = name
        self.mark = mark
        self.memo = memo
        self.result = result
        self.createdAt = .now
    }
}

let horseMark = ["◎", "○", "▲", "△", "✕"]
