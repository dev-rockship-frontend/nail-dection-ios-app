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
    
    var screenshot: UIImage
    
    var rangeOfDegree: Double
    
    var fromDistance: Double
    
    var toDistance: Double
    
    var frame: CGRect
    
    private lazy var boxesView: DrawingBoundingBoxView = {
        let view = DrawingBoundingBoxView()
        return view
    }()
    
    private lazy var videoPreview: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var imageBackground: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    private lazy var sceneView: ARSCNView = {
        let view = ARSCNView()
        return view
    }()
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    
    init(nails: [VNRecognizedObjectObservation],
         screenshot: UIImage,
         frame: CGRect,
         rangeOfDegree: Double,
         fromDistance: Double,
         toDistance: Double) {
        self.nails = nails
        self.screenshot = screenshot
        self.frame = frame
        self.rangeOfDegree = rangeOfDegree
        self.fromDistance = fromDistance
        self.toDistance = toDistance
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
        sceneView.automaticallyUpdatesLighting = true
        
        imageView = UIImageView()
        imageView.frame = self.frame
        imageView.image = screenshot
        view.addSubview(imageView)
        
        // Start AR session
        startARSession()
        boxesView = DrawingBoundingBoxView(frame: frame)
        boxesView.backgroundColor = .clear
        view.addSubview(boxesView)
        
        // Configure 3D distance after a delay (example: 3 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            
            self.boxesView.isDistance3D = true
            self.boxesView.predictedObjects = self.nails
            self.boxesView.sceneView = self.sceneView
            self.boxesView.startDistance = self.fromDistance
            self.boxesView.endDistance = self.toDistance
        }
        
        // Create UIImageView
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        boxesView.isDistance3D = false
    }
    
    func startARSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
    }
}



