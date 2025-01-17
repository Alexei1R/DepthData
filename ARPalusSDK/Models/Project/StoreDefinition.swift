//
//  StoreDefinition.swift
//  ARPalusSDK
//
//  Created by Александр Новиков on 16.01.2025.
//

import Foundation

struct StoreDefinition: Equatable, Codable {
    var baseType: Int
    var id: String
    var displayTitle: String
    var displayLine: String
    var root: Bool
    var locations: [Location]
    var nextIDs: [String]
}
