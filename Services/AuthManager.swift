import Foundation
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import CryptoKit
import SwiftUI
import Combine
import GoogleSignIn
import FirebaseCore

class AuthManager: NSObject, ObservableObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    static let shared = AuthManager()
    
    private var currentNonce: String?
    
    // 🔥 ТЕПЕР ПОВЕРТАЄ: Ім'я, Пошту, чи Новий це юзер (Bool), та його Дані з бази
    var onAuthSuccess: ((String, String, Bool, [String: Any]?) -> Void)?
    
    override init() {
        super.init()
    }
    
    // MARK: - EMAIL & PASSWORD AUTH
    func signUpWithEmail(email: String, password: String, name: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }
            
            let changeRequest = result?.user.createProfileChangeRequest()
            changeRequest?.displayName = name
            changeRequest?.commitChanges { _ in
                completion(true, nil)
            }
        }
    }
    
    // MARK: - APPLE SIGN IN
    func startSignInWithAppleFlow(onSuccess: @escaping (String, String, Bool, [String: Any]?) -> Void) {
        self.onAuthSuccess = onSuccess
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIWindow()
        }
        return window
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                guard let nonce = currentNonce else { return }
                guard let appleIDToken = appleIDCredential.identityToken else { return }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else { return }
                
                let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                               rawNonce: nonce,
                                                               fullName: appleIDCredential.fullName)
                
                Auth.auth().signIn(with: credential) { authResult, error in
                    if let error = error {
                        print("Apple Sign In Error: \(error.localizedDescription)")
                        return
                    }
                    
                    let name = (appleIDCredential.fullName?.givenName ?? "") + " " + (appleIDCredential.fullName?.familyName ?? "")
                    let finalName = name.trimmingCharacters(in: .whitespaces).isEmpty ? (authResult?.user.displayName ?? "User") : name
                    let email = appleIDCredential.email ?? authResult?.user.email ?? ""
                    
                    // 🔥 ПЕРЕВІРЯЄМО ЮЗЕРА У FIRESTORE 🔥
                    if let uid = authResult?.user.uid {
                        self.checkUserInFirestore(uid: uid, name: finalName, email: email)
                    }
                }
            }
        }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Sign in with Apple errored: \(error.localizedDescription)")
    }
    
    // MARK: - GOOGLE SIGN IN
    func startSignInWithGoogleFlow(onSuccess: @escaping (String, String, Bool, [String: Any]?) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else { return }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
            if let error = error {
                print("Google Sign In Error: \(error.localizedDescription)")
                return
            }
            
            guard let user = signInResult?.user,
                  let idToken = user.idToken?.tokenString else { return }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Firebase Google Auth Error: \(error.localizedDescription)")
                    return
                }
                
                let name = user.profile?.name ?? authResult?.user.displayName ?? "User"
                let email = user.profile?.email ?? authResult?.user.email ?? ""
                
                // 🔥 ПЕРЕВІРЯЄМО ЮЗЕРА У FIRESTORE 🔥
                if let uid = authResult?.user.uid {
                    self.checkUserInFirestore(uid: uid, name: name, email: email)
                }
            }
        }
    }
    
    // 🔥 ФУНКЦІЯ ПЕРЕВІРКИ ЮЗЕРА В БАЗІ 🔥
    private func checkUserInFirestore(uid: String, name: String, email: String) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, error in
            let exists = snapshot?.exists ?? false
            let data = snapshot?.data()
            
            DispatchQueue.main.async {
                // Якщо exists == true (юзер знайдений), значить isNewUser == false
                self.onAuthSuccess?(name, email, !exists, data)
            }
        }
    }
}

// MARK: - CRYPTO HELPERS FOR APPLE
private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    var randomBytes = [UInt8](repeating: 0, count: length)
    let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
    if errorCode != errSecSuccess { fatalError("Unable to generate nonce.") }
    let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    let nonce = randomBytes.map { charset[Int($0) % charset.count] }
    return String(nonce)
}

private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    let hashString = hashedData.compactMap { String(format: "%02x", $0) }.joined()
    return hashString
}
