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

    @State var email: String = ""
    @State var password: String = ""
    @State var mode: Mode = .signIn
    @State private var isSecure: Bool = true

    var onSignIn: (String, String) -> Void

    var body: some View {
        VStack() {
            Spacer()
            Image(.arpalusFullLogo)
                .resizable()
                .scaledToFit()
                .frame(width: 200)
            VStack(alignment: .leading, spacing: 16) {
                Text("Email")
                    .padding(.top, 50)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .frame(height: 50)
                    .padding(.leading)
                    .background(
                        Capsule()
                            .stroke(style: StrokeStyle(lineWidth: 2))
                            .foregroundStyle(Color(.lightGray))
                    )
                Text("Password")
                ZStack {
                    if isSecure {
                        SecureField("******", text: $password)
                            .frame(height: 50)
                            .padding(.leading)
                            .background(
                                Capsule()
                                    .stroke(style: StrokeStyle(lineWidth: 2))
                                    .foregroundStyle(Color(.lightGray))
                            )
                    } else {
                        TextField("******", text: $password)
                            .frame(height: 50)
                            .padding(.leading)
                            .background(
                                Capsule()
                                    .stroke(style: StrokeStyle(lineWidth: 2))
                                    .foregroundStyle(Color(.lightGray))
                            )
                    }
                    HStack {
                        Spacer()
                        Image(systemName: isSecure ? "eye" : "eye.slash")
                            .foregroundStyle(Color(.lightGray))
                            .onTapGesture {
                                isSecure.toggle()
                            }
                            .padding(.trailing)
                    }
                }
                .animation(.easeInOut, value: isSecure)
                HStack {
                    Spacer()
                    Button {
                        // Firebase reset password request
                    }
                    label: {
                        Text("Forgot Password ?")
                            .foregroundStyle(.blue)
                    }

                }
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
                    .bold()
                    .background(
                        Capsule()
                            .foregroundStyle(.blue)
                    )
                }
                Spacer()
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 24)
            .background(
                Color.white
                    .clipShape(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 20, topTrailing: 20)))
                    .ignoresSafeArea()
            )

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.blue.opacity(0.2))
    }
}

