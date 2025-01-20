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

        let options = FirebaseOptions(
            googleAppID: "1:105992620489:ios:69749ba467ceccd65f8018",
            gcmSenderID: "105992620489"
        )
        options.apiKey = "AIzaSyBp_O6bk8OTmaq_WT3OqctMmC0VnKYia_c"
        options.bundleID = "com.arpalus.sdk"
        options.projectID = "product-recognition-east-us"
        options.storageBucket = "product-recognition-east-us.firebasestorage.app"
        options.databaseURL = ""
        FirebaseApp.configure(name: appName, options: options)
        let app = FirebaseApp.app(name: appName)

        return app!
    }()
}

extension Firestore {
    static let sdk: Firestore = {
        Firestore.firestore(app: .sdk)
    }()
}

extension Storage {
    static let sdk: Storage = {
        Storage.storage(app: .sdk)
    }()
}

final class Initialisation {
    private let db = Firestore.sdk
    private let auth = Authentication()

    func intialise(email: String, password: String) async throws {
        try await auth.authenticate(email: email, password: password)
    }
}
