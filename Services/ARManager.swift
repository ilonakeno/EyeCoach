import Foundation
import ARKit
import SwiftUI
import Combine

class ARManager: NSObject, ObservableObject, ARSessionDelegate {
    @Published var session = ARSession()
    
    // --- ДАНІ ОЧЕЙ ---
    @Published var lookUp: Float = 0.0
    @Published var lookDown: Float = 0.0
    @Published var lookLeft: Float = 0.0
    @Published var lookRight: Float = 0.0
    @Published var blinkLeft: Float = 0.0
    @Published var blinkRight: Float = 0.0
    
    // Змінна для Vertical
    @Published var eyeVertical: Float = 0.0
    
    // Змінні для Figure 8
    @Published var lookUpRight: Float = 0.0
    @Published var lookDownRight: Float = 0.0
    @Published var lookUpLeft: Float = 0.0
    @Published var lookDownLeft: Float = 0.0
    
    // 👇 НОВА ЗМІННА: ЧИ ДИВИТЬСЯ ЛЮДИНА ПРЯМО?
    @Published var isLookingCenter: Bool = false
    
    // --- СТАТУС ---
    @Published var isFaceAligned: Bool = false
    @Published var alignmentMessage: String = "Starting camera..."

    override init() {
        super.init()
        session.delegate = self
    }

    func start() {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    func pause() {
        session.pause()
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let anchor = anchors.first as? ARFaceAnchor else {
            DispatchQueue.main.async { self.isFaceAligned = false }
            return
        }
        
        DispatchQueue.main.async {
            self.isFaceAligned = true
            self.alignmentMessage = ""
            
            // 1. ВЕРТИКАЛЬ
            let upL = anchor.blendShapes[.eyeLookUpLeft]?.floatValue ?? 0
            let upR = anchor.blendShapes[.eyeLookUpRight]?.floatValue ?? 0
            self.lookUp = (upL + upR) / 2.0
            
            let downL = anchor.blendShapes[.eyeLookDownLeft]?.floatValue ?? 0
            let downR = anchor.blendShapes[.eyeLookDownRight]?.floatValue ?? 0
            self.lookDown = (downL + downR) / 2.0
            
            self.eyeVertical = self.lookUp - self.lookDown
            
            // 2. ГОРИЗОНТАЛЬ (Виправлена дзеркальність)
            // Ліво для камери = Право для нас
            let leftEyeOut = anchor.blendShapes[.eyeLookOutLeft]?.floatValue ?? 0
            let rightEyeIn = anchor.blendShapes[.eyeLookInRight]?.floatValue ?? 0
            self.lookRight = (leftEyeOut + rightEyeIn) / 2.0
            
            let leftEyeIn = anchor.blendShapes[.eyeLookInLeft]?.floatValue ?? 0
            let rightEyeOut = anchor.blendShapes[.eyeLookOutRight]?.floatValue ?? 0
            self.lookLeft = (leftEyeIn + rightEyeOut) / 2.0
            
            // 3. ДІАГОНАЛІ
            self.lookUpRight   = (self.lookUp + self.lookRight) / 2.0
            self.lookDownRight = (self.lookDown + self.lookRight) / 2.0
            self.lookUpLeft    = (self.lookUp + self.lookLeft) / 2.0
            self.lookDownLeft  = (self.lookDown + self.lookLeft) / 2.0
            
            // 👇 4. РОЗРАХУНОК ЦЕНТРУ 👇
            // Якщо очі не дивляться сильно ні вгору, ні вниз, ні вліво, ні вправо
            let centerThreshold: Float = 0.15
            if self.lookUp < centerThreshold &&
               self.lookDown < centerThreshold &&
               self.lookLeft < centerThreshold &&
               self.lookRight < centerThreshold {
                self.isLookingCenter = true
            } else {
                self.isLookingCenter = false
            }
            
            // Кліпання
            self.blinkLeft = anchor.blendShapes[.eyeBlinkLeft]?.floatValue ?? 0
            self.blinkRight = anchor.blendShapes[.eyeBlinkRight]?.floatValue ?? 0
        }
    }
}
