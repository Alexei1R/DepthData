//
//  Deployment.swift
//  ARPalusSDK
//
//  Created by Александр Новиков on 17.01.2025.
//

import Foundation

struct Deployment: Codable, Equatable {
    var client: String
    var deployment: String
    var lastDeployment: String
    var project: String
    var projectVersion: Int
    var thumbnailsBanksCount: Int
    var thumbnailsVersion: Int
    var tutorialSlidesCount: Int
    var tutorialVersion: Int
}
