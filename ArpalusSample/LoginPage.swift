import Foundation
import UIKit
import SwiftUI
import FirebaseAuth


final class UserStore {
    func signIn(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func signUp(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}

struct LoginPage: View {
    enum Mode {
        case signIn
        case signUp
    }

    @State var email: String = ""
    @State var password: String = ""
    @State var mode: Mode = .signIn

    var body: some View {
        VStack {
            TextField("Email", text: $email)
            TextField("Password", text: $password)
            Spacer()
            Button(action: {
                switch mode {
                case .signIn:
                    UserStore().signIn(email: email, password: password) { result in
                        switch result {
                        case .success:
                            print("Sign in successful")
                        case .failure(let error):
                            print("Sign in failed: \(error)")
                        }
                    }
                case .signUp:
                    UserStore().signUp(email: email, password: password) { result in
                        switch result {
                        case .success:
                            print("Sign up successful")
                        case .failure(let error):
                            print("Sign up failed: \(error)")
                        }
                    }
                }
            }) {
                if mode == .signIn {
                    Text("Sign Up")
                } else {
                    Text("Sign In")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .foregroundColor(Color.white)
    }
}

