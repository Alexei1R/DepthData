//
//  StoreLocationTask.swift
//  ARPalusSDK
//
//  Created by Александр Новиков on 16.01.2025.
//

import Foundation

struct StoreLocationTask: Codable, Equatable {
    var baseType: Int
    var id: String
    var displayTitle: String
    var displayLine: String
    var nextIDs: [String]
}
