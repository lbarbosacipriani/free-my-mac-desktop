import Foundation

struct AppDocument: Identifiable, Hashable {
    let id: String
    let title: String
    let path: String
    let exists: Bool
    let sections: [DocumentSection]

    var statusLabel: String {
        exists ? "Disponivel" : "Ausente"
    }
}

struct DocumentSection: Identifiable, Hashable {
    let id: String
    let level: Int
    let title: String
    let body: String
}

struct DocumentSearchResult: Identifiable, Hashable {
    let id: String
    let documentTitle: String
    let sectionTitle: String
    let excerpt: String
}
