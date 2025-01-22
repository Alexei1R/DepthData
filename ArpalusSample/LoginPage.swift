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

class LoginViewModel: ObservableObject {
    enum Mode {
        case signIn
        case signUp
    }

    @Published var email: String = "victor@thenoughtyfox.com"
    @Published var password: String = "123456"
    @Published var mode: Mode = .signIn
    @Published var progress: Double = 0
    @Published var isLoading: Bool = false
}

struct LoginPage: View {
    @ObservedObject var viewModel: LoginViewModel
    @State private var isSecure: Bool = true

    var onSignIn: (String, String) -> Void

    var body: some View {
        ZStack {
            if !viewModel.isLoading {
                VStack() {
                    createLogo()
                    VStack(alignment: .leading, spacing: 16) {
                        createTextFields()
                        createFrogotPassword()
                        createSignInButton()
                        Spacer()
                    }
                    .foregroundStyle(.black)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity)
                    .background(
                        Color.white
                            .clipShape(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 20, topTrailing: 20)))
                            .ignoresSafeArea()
                    )

                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    Image(.background)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                )
            } else {
                ProgressView(progress: $viewModel.progress)
            }
        }
    }
}

private extension LoginPage {

    func createLogo() -> some View {
        Image(.arpalusFullLogo)
            .resizable()
            .scaledToFit()
            .frame(width: 150, height: 41)
            .padding(.top, 82)
            .padding(.bottom, 41)
    }

    func createTextFields() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("User Name")
                .padding(.top, 30)
                .padding(.bottom, 5)
                .bold()
            TextField("Enter email or username", text: $viewModel.email)
                .keyboardType(.emailAddress)
                .frame(height: 40)
                .padding(.leading)
                .background(
                    Capsule()
                        .stroke(style: StrokeStyle(lineWidth: 1))
                        .foregroundStyle(Color(.textFieldBorder))
                )
            Text("Password")
                .bold()
                .padding(.top, 30)
                .padding(.bottom, 5)
            ZStack {
                if isSecure {
                    SecureField("Enter your password", text: $viewModel.password)
                        .frame(height: 40)
                        .padding(.leading)
                        .background(
                            Capsule()
                                .stroke(style: StrokeStyle(lineWidth: 1))
                                .foregroundStyle(Color(.textFieldBorder))
                        )
                } else {
                    TextField("******", text: $viewModel.password)
                        .frame(height: 40)
                        .padding(.leading)
                        .background(
                            Capsule()
                                .stroke(style: StrokeStyle(lineWidth: 1))
                                .foregroundStyle(Color(.textFieldBorder))
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
        }
        .font(.system(size: 14))
    }

    func createSignInButton() -> some View {
        Button(action: {
            viewModel.isLoading = true
            switch viewModel.mode {
            case .signIn:
                UserStore().signIn(email: viewModel.email, password: viewModel.password) { result in
                    switch result {
                    case .success:
                        print("Sign in successful")
                        onSignIn(viewModel.email, viewModel.password)
                    case .failure(let error):
                        print("Sign in failed: \(error)")
                        viewModel.isLoading = false
                    }
                }
            case .signUp:
                UserStore().signUp(email: viewModel.email, password: viewModel.password) { result in
                    switch result {
                    case .success:
                        print("Sign up successful")
                        onSignIn(viewModel.email, viewModel.password)
                    case .failure(let error):
                        print("Sign up failed: \(error)")
                        viewModel.isLoading = false
                    }
                }
            }
        }) {
            HStack {
                if viewModel.mode == .signIn {
                    Text("Sign In")
                } else {
                    Text("Sign Up")
                }
            }
            .padding(.vertical)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .foregroundStyle(.white)
            .bold()
            .background(
                Capsule()
                    .foregroundStyle(.blue)
            )
        }
        .font(.system(size: 14))
    }

    func createFrogotPassword() -> some View {
        HStack {
            Spacer()
            Button {
                // Firebase reset password request
            }
            label: {
                Text("Forgot Password ?")
                    .foregroundStyle(.blue)
                    .font(.system(size: 12))

            }

        }
    }
}
