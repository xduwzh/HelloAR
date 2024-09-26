//
//  ContentView.swift
//  ARImageTracking
//
//  Created by Qi on 8/1/21.
//

import ARKit
import RealityKit
import SwiftUI

// Displays as a SwiftUI View
struct ContentView: View {
    var body: some View {
        return ARViewContainer().edgesIgnoringSafeArea(.all)
    }
}

struct ARViewContainer: UIViewRepresentable {
    var arView = ARView(frame: .zero)

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARViewContainer
        var videoPlayer: AVPlayer!
        
        init(parent: ARViewContainer) {
            self.parent = parent
        }
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            for anchor in anchors{
                if let imageAnchor = anchor as? ARImageAnchor{
                    let textEntity = createFloatingText(text: "wien")
                                    
                    let anchorEntity = AnchorEntity(anchor: imageAnchor)
                    anchorEntity.addChild(textEntity)
                                    
                    parent.arView.scene.addAnchor(anchorEntity)
                }
            }

            
        }
        

    }
    
    func makeUIView(context: Context) -> ARView {
        guard let referenceImages = ARReferenceImage.referenceImages(
            inGroupNamed: "AR Resources", bundle: nil)
        else {
            fatalError("Missing expected asset catalog resources.")
        }
        
        // Assigns coordinator to delegate the AR View
        arView.session.delegate = context.coordinator
        
        let configuration = ARImageTrackingConfiguration()
        configuration.isAutoFocusEnabled = true
        configuration.trackingImages = referenceImages
        configuration.maximumNumberOfTrackedImages = 1
        
        // Enables People Occulusion on supported iOS Devices
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            configuration.frameSemantics.insert(.personSegmentationWithDepth)
        } else {
            print("People Segmentation not enabled.")
        }

        arView.session.run(configuration)
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    

}

func createFloatingText(text: String) -> ModelEntity {
        let textMesh = MeshResource.generateText(text,
                                                 extrusionDepth: 0.003,
                                                 font: .systemFont(ofSize: 0.02),
                                                 containerFrame: .zero,
                                                 alignment: .center,
                                                 lineBreakMode: .byWordWrapping)
        let material = SimpleMaterial(color: .white, isMetallic: false)
        
        let textEntity = ModelEntity(mesh: textMesh, materials: [material])
        
    textEntity.position = [-0.01, 0.03, 0]
        
        return textEntity
    }
