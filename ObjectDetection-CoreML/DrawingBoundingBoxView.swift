//
//  DrawingBoundingBoxView.swift
//  SSDMobileNet-CoreML
//
//  Created by GwakDoyoung on 04/02/2019.
//  Copyright © 2019 tucan9389. All rights reserved.
//

import UIKit
import Vision

class DrawingBoundingBoxView: UIView {
    
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
        
        drawMinimumSpanningTree(context: context, points: points)
    }
    
    func drawMinimumSpanningTree(context: CGContext, points: [CGPoint]) {
        let edges = createEdges(points: points)
        let mstEdges = kruskal(points: points, edges: edges)
        
        context.beginPath()
        for edge in mstEdges {
            context.move(to: edge.0)
            context.addLine(to: edge.1)
        }
        context.strokePath()
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
    func toString(digit: Int) -> String {
        let xStr = String(format: "%.\(digit)f", origin.x)
        let yStr = String(format: "%.\(digit)f", origin.y)
        let wStr = String(format: "%.\(digit)f", width)
        let hStr = String(format: "%.\(digit)f", height)
        return "(\(xStr), \(yStr), \(wStr), \(hStr))"
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
