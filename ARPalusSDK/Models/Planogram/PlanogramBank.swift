import Foundation

struct PlanogramBank: Codable, Equatable {
    var version: Int
    var planograms: [Planogram]
}
