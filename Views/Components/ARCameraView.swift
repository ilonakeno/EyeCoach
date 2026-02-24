import SwiftUI
import ARKit

// Це міст між SwiftUI та складним світом UIKit/ARKit
struct ARCameraView: UIViewRepresentable {
    @ObservedObject var arManager: ARManager
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        
        // Підключаємо нашу сесію з менеджера до цього екрану
        arView.session = arManager.session
        arView.automaticallyUpdatesLighting = true
        
        // (Опціонально) Можна додати 3D маску на обличчя тут, але поки залишимо чистим
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // Тут оновлюємо вигляд, якщо треба (поки порожньо)
    }
}
