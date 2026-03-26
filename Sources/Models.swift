import SwiftData
import Foundation

@Model
class Race {
    var name: String
    var date: Date
    var venue: String
    var raceNumber: Int
    @Relationship(deleteRule: .cascade) var horses: [Horse] = []

    init(name: String = "", date: Date = .now, venue: String = "", raceNumber: Int = 0) {
        self.name = name
        self.date = date
        self.venue = venue
        self.raceNumber = raceNumber
    }

    var displayName: String {
        let r = raceNumber > 0 ? "第\(raceNumber)R" : ""
        let v = venue.isEmpty ? "" : venue
        let n = name.isEmpty ? "" : name

        if !n.isEmpty { return n }
        if !v.isEmpty && !r.isEmpty { return "\(v) \(r)" }
        if !v.isEmpty { return v }
        if !r.isEmpty { return r }
        return "無名レース"
    }
}

@Model
class Horse {
    var name: String
    var mark: String
    var memo: String
    var result: String
    var createdAt: Date
    var horseNumber: Int

    init(name: String, mark: String = "▲", memo: String = "", result: String = "", horseNumber: Int = 0) {
        self.name = name
        self.mark = mark
        self.memo = memo
        self.result = result
        self.createdAt = .now
        self.horseNumber = horseNumber
    }
}

let horseMark = ["◎", "○", "▲", "△", "✕"]
let jraVenues = ["札幌", "函館", "福島", "新潟", "中山", "東京", "中京", "京都", "阪神", "小倉"]
