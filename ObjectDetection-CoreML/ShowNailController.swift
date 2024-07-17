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
    var boxesView: DrawingBoundingBoxView!
    var videoPreview: UIView!
    private lazy var imageBackground: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    var background: UIImage
    var sceneView: ARSCNView!
    
    
    
    init(nails: [VNRecognizedObjectObservation], background: UIImage) {
        self.nails = nails
        self.background = background
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        sceneView = ARSCNView()
        view.addSubview(sceneView)
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sceneView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        view.addSubview(imageBackground)
        imageBackground.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageBackground.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageBackground.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            imageBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        imageBackground.image = background
        
        startARSession()
        
        boxesView = DrawingBoundingBoxView(frame: view.bounds)
        boxesView.backgroundColor = .clear
        view.addSubview(boxesView)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.boxesView.isDistance3D = true
            self.boxesView.predictedObjects = self.nails
            self.boxesView.sceneView = self.sceneView
            
        }
        
//        boxesView.predictedObjects = nails
//        boxesView.sceneView = sceneView
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


