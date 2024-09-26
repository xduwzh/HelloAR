//
//  CustomARView.swift
//  AR Toy Helicopter
//
//  Created by 吴征航 on 2024/4/18.
//

import Foundation
import ARKit
import RealityKit
import SwiftUI
import FocusEntity
import SceneKit

class CustomARView: ARView,ARSCNViewDelegate {
    var timer: Timer?
    var planeEntity: Entity?
    var controllerData: ControllerData?
    var focus: FocusEntity?
    
    private let accelerationFactor: Float = 0.00008
    private let rotationFactor: Float = 0.0007
    let moveSpeed: Float = 0.013
    
    
    required init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        
    }
    
    dynamic required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(controllerData: ControllerData){
        self.init(frame: UIScreen.main.bounds)
        
        self.controllerData = controllerData
        
        startPlaneDetection()
        focus = FocusEntity(on: self, focus: .classic)
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:))))
    }
    
    @objc
    func handleTap(recognizer: UITapGestureRecognizer){
        focus?.isEnabled = false
        let tapLocation = recognizer.location(in: self)
        
        let results = self.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal)
        
        if let firstResult = results.first{
            let worldPos = simd_make_float3(firstResult.worldTransform.columns.3)
            let plane = try? Entity.load(named: "toy_biplane_idle.usdz")
            placeObject(object: plane!, at: worldPos)
            self.removeGestureRecognizer(recognizer)
            controllerData?.planeSet = true;
            startRisingTimer()
            
        }
        
    }
    
    func startPlaneDetection() {
        self.automaticallyConfigureSession = true;
        let configuration = ARWorldTrackingConfiguration();
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            fatalError("Missing expected asset catalog resources.")
        }
        
        configuration.detectionImages = referenceImages
        
        self.session.run(configuration)
    }
    
    
    func placeObject(object: Entity, at location: SIMD3<Float>){
        let objectAnchor = AnchorEntity(world: location)
        objectAnchor.addChild(object)
        self.scene.addAnchor(objectAnchor)
        planeEntity = object
    }
    
    func startRisingTimer() {
        timer = Timer.scheduledTimer(timeInterval: 0.001, target: self, selector: #selector(movePlane), userInfo: nil, repeats: true)
    }
    
    @objc func movePlane() {
        guard let plane = planeEntity else { return }
        
        plane.position.y += accelerationFactor * Float(controllerData!.leftStick)
        
        
        let forwardVector = plane.transform.matrix.columns.2
        let movementDirection = SIMD3<Float>(forwardVector.x, forwardVector.y, forwardVector.z) * Float(controllerData!.rightStickY) * moveSpeed
        plane.position += movementDirection
        
        let rotationAngle = -Float(controllerData!.rightStickX) * rotationFactor
        let rotation = simd_quatf(angle: rotationAngle, axis: [0, 1, 0])
        plane.orientation *= rotation
        
    }
    
}

var textShown = false
extension ARView:ARSessionDelegate{
    public func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors{
            if let imageAnchor = anchor as? ARImageAnchor{
                let textEntity = createFloatingText(text: "toothpaste")
                
                let anchorEntity = AnchorEntity(anchor: imageAnchor)
                anchorEntity.addChild(textEntity)
                
                self.scene.addAnchor(anchorEntity)
            }
        }
        
    }
}



private func createFloatingText(text: String) -> ModelEntity {
    let textMesh = MeshResource.generateText(text,
                                             extrusionDepth: 0.02,
                                             font: .systemFont(ofSize: 0.2),
                                             containerFrame: .zero,
                                             alignment: .center,
                                             lineBreakMode: .byWordWrapping)
    
    let material = SimpleMaterial(color: .white, isMetallic: false)
    
    let textEntity = ModelEntity(mesh: textMesh, materials: [material])
    
    textEntity.position = [0, 0.05, 0]
    
    return textEntity
}

