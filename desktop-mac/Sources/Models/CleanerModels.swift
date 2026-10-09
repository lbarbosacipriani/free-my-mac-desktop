import Foundation

struct Candidate: Identifiable, Codable, Hashable {
    let id: String
    let kind: String
    let path: String
    let sizeBytes: Int
    let modifiedAt: String
    let ageDays: Int
    let reason: String
    let risk: String

    enum CodingKeys: String, CodingKey {
        case id
        case kind
        case path
        case sizeBytes = "size_bytes"
        case modifiedAt = "modified_at"
        case ageDays = "age_days"
        case reason
        case risk
    }

    var displayName: String {
        URL(fileURLWithPath: path).lastPathComponent
    }

    var kindLabel: String {
        switch kind {
        case "cache": return "Cache"
        case "log": return "Log"
        case "installer": return "Instalador"
        case "download": return "Download"
        case "devdata": return "Xcode DerivedData"
        case "devarchive": return "Xcode Archive"
        case "xcode-junk": return "Xcode"
        case "xcode-log": return "Xcode Logs"
        case "document-version": return "Document Versions"
        default: return kind
        }
    }

    var kindSymbol: String {
        switch kind {
        case "cache": return "externaldrive"
        case "log": return "doc.text"
        case "installer": return "shippingbox"
        case "download": return "arrow.down.circle"
        case "devdata", "devarchive", "xcode-junk": return "hammer"
        case "xcode-log": return "doc.text.magnifyingglass"
        case "document-version": return "clock.arrow.circlepath"
        default: return "doc"
        }
    }

    var riskLabel: String {
        switch risk {
        case "baixo": return "Baixo"
        case "medio": return "Medio"
        case "alto": return "Alto"
        default: return risk
        }
    }
}

struct ScanReport: Codable {
    let generatedAt: String
    let policy: ScanPolicy
    let totalSizeBytes: Int
    let candidates: [Candidate]

    enum CodingKeys: String, CodingKey {
        case generatedAt = "generated_at"
        case policy
        case totalSizeBytes = "total_size_bytes"
        case candidates
    }
}

struct ScanPolicy: Codable {
    let scanHome: String?
    let minSizeMB: Int?
    let olderThanDays: Int?
    let includeSystem: Bool?
    let note: String?

    enum CodingKeys: String, CodingKey {
        case scanHome = "scan_home"
        case minSizeMB = "min_size_mb"
        case olderThanDays = "older_than_days"
        case includeSystem = "include_system"
        case note
    }
}

struct ScanStatusPayload: Codable {
    let scan: ScanStatus
    let report: ScanReport?
}

struct ScanStatus: Codable {
    let running: Bool
    let startedAt: Double?
    let finishedAt: Double?
    let elapsedSeconds: Double
    let message: String
    let error: String?
    let candidateCount: Int
    let totalSizeBytes: Int

    enum CodingKeys: String, CodingKey {
        case running
        case startedAt = "started_at"
        case finishedAt = "finished_at"
        case elapsedSeconds = "elapsed_seconds"
        case message
        case error
        case candidateCount = "candidate_count"
        case totalSizeBytes = "total_size_bytes"
    }

    static let idle = ScanStatus(
        running: false,
        startedAt: nil,
        finishedAt: nil,
        elapsedSeconds: 0,
        message: "Nenhuma varredura em andamento.",
        error: nil,
        candidateCount: 0,
        totalSizeBytes: 0
    )
}

struct QuarantineSession: Identifiable, Codable {
    var id: String { session }

    let session: String
    let path: String
    let ageDays: Int
    let sizeBytes: Int
    let itemCount: Int
    let items: [QuarantineItem]

    enum CodingKeys: String, CodingKey {
        case session
        case path
        case ageDays = "age_days"
        case sizeBytes = "size_bytes"
        case itemCount = "item_count"
        case items
    }
}

struct QuarantineItem: Identifiable, Codable {
    let id: String
    let kind: String
    let originalPath: String
    let quarantinePath: String
    let sizeBytes: Int
    let reason: String
    let sha256: String?
    let movedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case kind
        case originalPath = "original_path"
        case quarantinePath = "quarantine_path"
        case sizeBytes = "size_bytes"
        case reason
        case sha256
        case movedAt = "moved_at"
    }
}

struct QuarantineResponse: Codable {
    let result: QuarantineResult
}

struct QuarantineResult: Codable {
    let moved: Int
    let session: String?
    let manifest: String?
    let errors: [String]
}

struct RestoreResponse: Codable {
    let result: RestoreResult
}

struct RestoreResult: Codable {
    let restored: Int
    let errors: [String]
}

struct SessionsResponse: Codable {
    let sessions: [QuarantineSession]
}

struct PurgeResponse: Codable {
    let sessions: [QuarantineSession]
}

extension Int {
    var humanSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(self), countStyle: .file)
    }
}

extension Double {
    var secondsLabel: String {
        "\(Int(self.rounded()))s"
    }
}
