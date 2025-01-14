import FirebaseCore
import FirebaseFirestore
import FirebaseStorage

fileprivate final class SDKBundle {}
extension Bundle {
    static var sdk: Bundle {
        Bundle(for: SDKBundle.self)
    }
}

extension FirebaseApp {
    static let appName = "ARpalusSDK"

    static let sdk: FirebaseApp = {
        let optionsPath = Bundle.sdk.path(forResource: "firebase-options", ofType: "plist")!
        let options = FirebaseOptions(contentsOfFile: optionsPath)!
        let app = FirebaseApp(instanceWithName: appName, options: options)

        return app
    }()
}

extension Firestore {
    static let sdk: Firestore = {
        Firestore.firestore(app: .sdk)
    }()
}

extension Storage {
    static let sdk = Storage {
        Storage.storage(app: .sdk)
    }()
}

final class Initialisation {
    private let db = Firestore.sdk
    private let auth = Authentication()

    func intialise(with token: String) {
        auth.authenticate(token: token)
        
    }
}
