import Foundation

struct CVModelsBank: Codable, Equatable {
    var version: Int
    var cvModels: [CVModel]
}
