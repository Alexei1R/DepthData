//
//  ViewController.swift
//  ArpalusSample
//
//  Created by Lisnic Victor on 31.12.2024.
//

import UIKit
import ARKit
import RealityKit
import SceneKit
import SwiftUI
import ARPalusSDK

//class ViewController: UIViewController {
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        let loginPage = LoginPage(, onSignIn: <#() -> Void#>)
//        let hostingController = UIHostingController(rootView: loginPage)
//        addChild(hostingController)
//        view.addSubview(hostingController.view)
//
//        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
//                NSLayoutConstraint.activate([
//                    hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
//                    hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//                    hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//                    hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
//        ])
//
//        // Finalize the child view controller addition
//        hostingController.didMove(toParent: self)
//    }
//
//    func proceed() {
//        navigationController?.pushViewController(ScanningViewController(), animated: true)
//    }
//}
//
class ViewController: UIHostingController<LoginPage> {
    init() {
        super.init(rootView: LoginPage(onSignIn: {_,_ in }))
        rootView = LoginPage(onSignIn: proceed)
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func proceed(email: String, password: String) {
        ArpalusSDK.start(email: email, password: password) {
            self.navigationController?.pushViewController(ScanningViewController(), animated: true)
        }
    }
}
