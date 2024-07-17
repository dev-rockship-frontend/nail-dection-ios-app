//
//  DrawingBoundingBoxView.swift
//  SSDMobileNet-CoreML
//
//  Created by GwakDoyoung on 04/02/2019.
//  Copyright © 2019 tucan9389. All rights reserved.
//

import UIKit
import Vision
import ARKit

class DrawingBoundingBoxView: UIView {
    
    var isDistance3D: Bool = false
    
    enum Axis {
        case x
        case y
    }
    
    var sceneView: ARSCNView?
    
    static private var colors: [String: UIColor] = [:]
    
    public func labelColor(with label: String) -> UIColor {
        if let color = DrawingBoundingBoxView.colors[label] {
            return color
        } else {
            let color = UIColor(hue: .random(in: 0...1), saturation: 1, brightness: 1, alpha: 0.8)
            DrawingBoundingBoxView.colors[label] = color
            return color
        }
    }
    
    public var predictedObjects: [VNRecognizedObjectObservation] = [] {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.clear(rect)
        drawBoundingBoxes()
        drawConnectingLines(context: context)
    }
    
    func drawBoundingBoxes() {
        subviews.forEach({ $0.removeFromSuperview() })
        
        for prediction in predictedObjects {
            createLabelAndBox(prediction: prediction)
        }
    }
    
    func createLabelAndBox(prediction: VNRecognizedObjectObservation) {
        let scale = CGAffineTransform.identity.scaledBy(x: bounds.width, y: bounds.height)
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1)
        let bgRect = prediction.boundingBox.applying(transform).applying(scale)
        
        let bgView = UIView(frame: bgRect)
        bgView.layer.borderColor = UIColor.green.cgColor
        bgView.layer.borderWidth = 1
        bgView.backgroundColor = UIColor.clear
        addSubview(bgView)
    }
    
    func drawConnectingLines(context: CGContext) {
        guard predictedObjects.count > 1 else { return }
        
        let points = predictedObjects.map { prediction -> CGPoint in
            let scale = CGAffineTransform.identity.scaledBy(x: bounds.width, y: bounds.height)
            let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1)
            let centerRect = prediction.boundingBox.applying(transform).applying(scale)
            return CGPoint(x: centerRect.midX, y: centerRect.midY)
        }
        
        context.setStrokeColor(UIColor.red.cgColor)
        context.setLineWidth(2.0)
        
        drawLinesThroughPoints(context: context, points: points)
    }
    
    func displayDistanceLabel(at point: CGPoint, distance: String) {
        let distanceLabel = UILabel()
        distanceLabel.text = distance //String(format: "%.2f", distance)
        distanceLabel.font = UIFont.systemFont(ofSize: 12)
        distanceLabel.textColor = .white
        distanceLabel.sizeToFit()
        distanceLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        distanceLabel.layer.cornerRadius = 5
        distanceLabel.clipsToBounds = true
        distanceLabel.center = point
        addSubview(distanceLabel)
    }
    
    
  
    private func calculateDistance(from point1: SCNVector3, to point2: SCNVector3) -> Float {
        let vector = SCNVector3(point2.x - point1.x, point2.y - point1.y, point2.z - point1.z)
        return sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
    }
    
    private func convertBoundingBoxTo3D(_ point: CGPoint) -> SCNVector3? {
        guard let sceneView = self.sceneView else {
            return nil
        }
        
        let hitTestResults = sceneView.hitTest(point, types: .featurePoint)
        if let result = hitTestResults.first {
            let position = result.worldTransform.columns.3
            return SCNVector3(position.x, position.y, position.z)
        }
        
        return nil
    }


    
    func drawLinesThroughPoints(context: CGContext, points: [CGPoint]) {

//        214   463
        let edges = createEdges(points: points)
        let mstEdges = kruskal(points: points, edges: edges)

        context.beginPath()
        
        for edge in mstEdges {

            let x1 = edge.0.x, y1 = edge.0.y
            let x2 = edge.1.x, y2 = edge.1.y

            let a = isAngleOfDeviationGreaterThanFiveDegrees(x1: x1, y1: y1, x2: x2, y2: y2, withRespectTo: .x).rounded()
            let b = isAngleOfDeviationGreaterThanFiveDegrees(x1: x1, y1: y1, x2: x2, y2: y2, withRespectTo: .y).rounded()

            if a <= 10 || b <= 10 {
                context.move(to: edge.0)
                context.addLine(to: edge.1)
                
                if isDistance3D {
                    let point1_3D = convertBoundingBoxTo3D(edge.0)
                    let point2_3D  = convertBoundingBoxTo3D(edge.1)
                    if let point1_3D = point1_3D, let point2_3D = point2_3D {
                        let distance = calculateDistance(from: point1_3D, to: point2_3D)
                        
                        let midpoint = CGPoint(x: (edge.0.x + edge.1.x) / 2, y: (edge.0.y + edge.1.y) / 2)
                        displayDistanceLabel(at: midpoint, distance: "\(Int(distance * 100))")
                    } else {
                        print("Failed to get 3D coordinates for nails.")
                    }
                }
            }
        }
        context.strokePath()
    }
    

    func isAngleOfDeviationGreaterThanFiveDegrees(x1: CGFloat, y1: CGFloat, x2: CGFloat, y2: CGFloat, withRespectTo axis: Axis) -> CGFloat {
        var difference1: CGFloat
        var difference2: CGFloat
        
        switch axis {
        case .x:
            difference1 = abs(x2 - x1)
            difference2 = abs(y2 - y1)
        case .y:
            difference1 = abs(y2 - y1)
            difference2 = abs(x2 - x1)
        }
        
        // Calculate the length of the vector projection
        let length = sqrt(difference1 * difference1 + difference2 * difference2)
        
        //         Calculate the cosine of the angle
        let cosTheta = difference1 / length
        
        // Calculate the angle in radians
        let theta = acos(cosTheta)
        
        // Convert the angle to degrees
        let thetaInDegrees = theta * 180.0 / .pi
        
        // Check if the angle is greater than 5 degrees
        return thetaInDegrees
    }
    
    func createEdges(points: [CGPoint]) -> [(CGPoint, CGPoint, CGFloat)] {
        var edges: [(CGPoint, CGPoint, CGFloat)] = []
        for i in 0..<points.count {
            for j in i+1..<points.count {
                let distance = hypot(points[i].x - points[j].x, points[i].y - points[j].y)
                edges.append((points[i], points[j], distance))
            }
        }
        return edges
    }
    
    func calculateDistanceBetweenPoints(point1: CGPoint, point2: CGPoint) -> CGFloat {
        let deltaX = point2.x - point1.x
        let deltaY = point2.y - point1.y
        return sqrt(deltaX * deltaX + deltaY * deltaY)
    }
    
    func kruskal(points: [CGPoint], edges: [(CGPoint, CGPoint, CGFloat)]) -> [(CGPoint, CGPoint)] {
        var parent = [Int](0..<points.count)
        var rank = [Int](repeating: 0, count: points.count)
        
        func find(_ x: Int) -> Int {
            if parent[x] != x {
                parent[x] = find(parent[x])
            }
            return parent[x]
        }
        
        func union(_ x: Int, _ y: Int) {
            let rootX = find(x)
            let rootY = find(y)
            if rootX != rootY {
                if rank[rootX] < rank[rootY] {
                    parent[rootX] = rootY
                } else if rank[rootX] > rank[rootY] {
                    parent[rootY] = rootX
                } else {
                    parent[rootY] = rootX
                    rank[rootX] += 1
                }
            }
        }
        
        let sortedEdges = edges.sorted { $0.2 < $1.2 }
        var mstEdges: [(CGPoint, CGPoint)] = []
        
        for edge in sortedEdges {
            let (point1, point2, _) = edge
            let index1 = points.firstIndex(of: point1)!
            let index2 = points.firstIndex(of: point2)!
            
            if find(index1) != find(index2) {
                mstEdges.append((point1, point2))
                union(index1, index2)
            }
        }
        
        return mstEdges
    }
}

extension VNRecognizedObjectObservation {
    var label: String? {
        return self.labels.first?.identifier
    }
}

extension CGRect {
    func toString(digit: Int, width: CGFloat, height: CGFloat) -> String {
        let xStr = String(format: "%.\(digit)f", origin.x * width)
        let yStr = String(format: "%.\(digit)f", origin.y * height)
        return "(\(xStr), \(yStr))"
    }
}

extension CGPoint: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
    
    public static func == (lhs: CGPoint, rhs: CGPoint) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
}
