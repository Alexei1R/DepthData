import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

extension Auth {
    static let sdk: Auth = {
        return Auth.auth(app: .sdk)
    }()
}

final class Authentication {
    func authenticate(token: String) {
        Auth.sdk.signIn(withCustomToken: token) { result, error in
            
        }
    }
}
