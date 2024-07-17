//
//  ShowNailController.swift
//  YOLO
//
//  Created by Hoang Son Vo Phuoc on 7/16/24.
//  Copyright © 2024 Ultralytics. All rights reserved.
//

import UIKit
import Vision
import ARKit

class ShowNailController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    var nails: [VNRecognizedObjectObservation]
    var screenshot: UIImage!
    var boxesView: DrawingBoundingBoxView!
    var sceneView: ARSCNView!
    var imageView: UIImageView!
    var frame: CGRect
    
    init(nails: [VNRecognizedObjectObservation], screenshot: UIImage, frame: CGRect) {
        self.nails = nails
        self.screenshot = screenshot
        self.frame = frame
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        sceneView = ARSCNView(frame: frame)
        view.addSubview(sceneView)
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        imageView = UIImageView()
        imageView.frame = self.frame
        imageView.image = screenshot  // Set your image here
        view.addSubview(imageView)
        
        // Start AR session
        startARSession()
        boxesView = DrawingBoundingBoxView(frame: frame)
        boxesView.backgroundColor = .clear
        view.addSubview(boxesView)
        
        // Configure 3D distance after a delay (example: 3 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.boxesView.isDistance3D = true
            self.boxesView.predictedObjects = self.nails
            self.boxesView.sceneView = self.sceneView
        }
        
        // Create UIImageView
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        boxesView.isDistance3D = false
    }
    
    func startARSession() {
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
}
