//
//  DistanceViewController.swift
//  ObjectDetection-CoreML
//
//  Created by Hoang Son Vo Phuoc on 7/4/24.
//  Copyright © 2024 tucan9389. All rights reserved.
//

import UIKit
import ARKit

class DistanceViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    var sceneView: ARSCNView!
    var distanceLabel: UILabel!
    var resetButton: UIButton!
    var anchors: [ARAnchor] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView = ARSCNView()
        view.addSubview(sceneView)
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        //        let configuration = ARWorldTrackingConfiguration()
        //        sceneView.session.run(configuration)
        
        setupDistanceLabel()
        setupResetButton()
        
        sceneView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.left.right.equalToSuperview()
        }
        
        startARSession()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Restart the AR session when the view appears
        startARSession()
        distanceLabel.text = "Distance: 0 cm"
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    func startARSession() {
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func setupDistanceLabel() {
        distanceLabel = UILabel()
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false
        distanceLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        distanceLabel.textColor = UIColor.white
        distanceLabel.textAlignment = .center
        distanceLabel.text = "Distance: 0 cm"
        self.view.addSubview(distanceLabel)
        
        distanceLabel.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-35)
            make.left.right.equalToSuperview().inset(50)
        }
    }
    
    func setupResetButton() {
        resetButton = UIButton(type: .system)
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.setTitle("Reset", for: .normal)
        resetButton.addTarget(self, action: #selector(resetAnchors), for: .touchUpInside)
        view.addSubview(resetButton)
        
        resetButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(50)
            make.centerX.equalToSuperview()
            make.width.equalTo(48)
            make.height.equalTo(40)
        }
    }
    
    @objc func resetAnchors() {
        anchors.removeAll()
        distanceLabel.text = "Distance: 0 cm"
        
        // Remove all existing nodes
        sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
    }
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: sceneView)
        
        let hitTestResults = sceneView.hitTest(location, types: .featurePoint)
        if let result = hitTestResults.first {
            let anchor = ARAnchor(transform: result.worldTransform)
            sceneView.session.add(anchor: anchor)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        let sphere = SCNSphere(radius: 0.003)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        sphere.materials = [material]
        
        let sphereNode = SCNNode(geometry: sphere)
        node.addChildNode(sphereNode)
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        self.anchors.append(contentsOf: anchors)
        if self.anchors.count == 2 {
            calculateDistance()
        }
    }
    
    func calculateDistance() {
        guard anchors.count == 2 else { return }
        
        let transform1 = anchors[0].transform
        let transform2 = anchors[1].transform
        
        let position1 = SCNVector3(transform1.columns.3.x, transform1.columns.3.y, transform1.columns.3.z)
        let position2 = SCNVector3(transform2.columns.3.x, transform2.columns.3.y, transform2.columns.3.z)
        
        let distance = distanceBetweenPoints(point1: position1, point2: position2)
        let distanceInCentimeters = distance * 100
        
        distanceLabel.text = String(format: "Distance: %.2f cm", distanceInCentimeters)
    }
    
    func distanceBetweenPoints(point1: SCNVector3, point2: SCNVector3) -> Float {
        let vector = SCNVector3(point2.x - point1.x, point2.y - point1.y, point2.z - point1.z)
        return sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
    }
}

