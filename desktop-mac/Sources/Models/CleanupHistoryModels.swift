import Foundation

struct CleanupHistoryEntry: Identifiable, Codable, Hashable {
    let id: String
    let date: String
    let action: String
    let itemCount: Int
    let bytes: Int
    let detail: String

    var dateLabel: String {
        date.replacingOccurrences(of: "T", with: " ").replacingOccurrences(of: "Z", with: "")
    }
}

struct DeveloperTarget: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let risk: String
    let examples: [String]
}
