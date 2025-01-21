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
    func authenticate(email: String, password: String) async throws -> AuthDataResult {
        let result = try await Auth.sdk.signIn(withEmail: email, password: password)
        return result
    }
}
