//
//  LocalStorage.swift
//  ARPalusSDK
//
//  Created by Александр Новиков on 16.01.2025.
//

import Foundation

final class LocalStorage {

    static let shared = LocalStorage()

    @Defaults("com.arpalus.sdk.user.settings")
    var userSettings: UserSettings? = nil

    @Defaults("com.arpalus.sdk.app.settings")
    var appSettings: AppSettingsVersion? = nil

    @Defaults("com.arpalus.sdk.deployments.settings")
    var deploymentSettings: Deployment? = nil

    @Defaults("com.arpalus.sdk.cvModelsBank")
    var cvModelsBank: CVModelsBank? = nil

    @Defaults("com.arpalus.sdk.planogramBank")
    var planogramBank: PlanogramBank? = nil

    @Defaults("com.arpalus.sdk.project")
    var project: Project? = nil
}
