import Foundation
import UIKit
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import ArpalusSDK

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

            if let token = result?.credential?.idToken {
                print(token)
            }
        }
    }
}

struct LoginPage: View {
    enum Mode {
        case signIn
        case signUp
    }

    @State var email: String = "victor@thenoughtyfox.com"
    @State var password: String = "123456"
    @State var mode: Mode = .signIn

    var onSignIn: (String, String) -> Void

    var body: some View {
        VStack() {
            Spacer()
            VStack(alignment: .leading) {
                TextField("Email", text: $email)
                Divider()
                TextField("Password", text: $password)
                Divider()
            }
            .foregroundStyle(.black)
            Button(action: {
                switch mode {
                case .signIn:
                    UserStore().signIn(email: email, password: password) { result in
                        switch result {
                        case .success:
                            print("Sign in successful")
                            onSignIn(email, password)
                        case .failure(let error):
                            print("Sign in failed: \(error)")
                        }
                    }
                case .signUp:
                    UserStore().signUp(email: email, password: password) { result in
                        switch result {
                        case .success:
                            print("Sign up successful")
                            onSignIn(email, password)
                        case .failure(let error):
                            print("Sign up failed: \(error)")
                        }
                    }
                }
            }) {
                HStack {
                    if mode == .signIn {
                        Text("Sign In")
                    } else {
                        Text("Sign Up")
                    }
                }
                .padding(.vertical)
                .frame(maxWidth: .infinity)
                .foregroundStyle(.white)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundStyle(.blue)
                )
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

