import Foundation

enum CleanupRuleStatus: String, Codable, CaseIterable {
    case active
    case suggested
    case ignored

    var label: String {
        switch self {
        case .active: return "Ativa"
        case .suggested: return "Sugerida"
        case .ignored: return "Ignorada"
        }
    }
}

enum CleanupRuleMatchMode: String, Codable {
    case files
    case topLevelDirectories
    case namedDirectoriesRecursive
}

struct CleanupRule: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let pathPattern: String
    let kind: String
    let risk: String
    let reason: String
    let sourceDocument: String
    let sourceSection: String
    let matchMode: CleanupRuleMatchMode
    let targetNames: [String]
    var status: CleanupRuleStatus

    var statusLabel: String { status.label }

    var expandedPath: String {
        NSString(string: pathPattern).expandingTildeInPath
    }
}
