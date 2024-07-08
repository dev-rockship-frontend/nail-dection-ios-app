//
//  CoordinateSystemView.swift
//  ObjectDetection-CoreML
//
//  Created by Huy Dang on 24/6/24.
//  Copyright © 2024 tucan9389. All rights reserved.
//

import UIKit

class CoordinateSystemView: UIView {
    
    // Properties for grid settings
    var gridSpacingX: CGFloat = 0.0
    var gridSpacingY: CGFloat = 0.0
    
    let axisLineWidth: CGFloat = 2.0
    let gridLineWidth: CGFloat = 0.5
    let axisColor: UIColor = .blue
    let gridColor: UIColor = .lightGray
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        // Get the context
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        gridSpacingX =  rect.width / 20
        gridSpacingY =  rect.height / 20
        // Draw the grid
//        drawGrid(in: context, rect: rect)
        
        // Draw the x and y axes
        drawAxes(in: context, rect: rect)
    }
    
    private func drawGrid(in context: CGContext, rect: CGRect) {
        context.setLineWidth(gridLineWidth)
        context.setStrokeColor(gridColor.cgColor)
        
        // Vertical grid lines
        for x in stride(from: rect.origin.x, through: rect.size.width, by: gridSpacingX) {
            context.move(to: CGPoint(x: x, y: rect.origin.y))
            context.addLine(to: CGPoint(x: x, y: rect.size.height))
        }
        
        // Horizontal grid lines
        for y in stride(from: rect.origin.y, through: rect.size.height, by: gridSpacingY) {
            context.move(to: CGPoint(x: rect.origin.x, y: y))
            context.addLine(to: CGPoint(x: rect.size.width, y: y))
        }
        
        context.strokePath()
    }
    
    private func drawAxes(in context: CGContext, rect: CGRect) {
        context.setLineWidth(axisLineWidth)
        context.setStrokeColor(axisColor.cgColor)
        
        // Draw x-axis
        context.move(to: CGPoint(x: rect.origin.x, y: rect.midY))
        context.addLine(to: CGPoint(x: rect.size.width, y: rect.midY))
        
        // Draw y-axis
        context.move(to: CGPoint(x: rect.midX, y: rect.origin.y))
        context.addLine(to: CGPoint(x: rect.midX, y: rect.size.height))
        
        context.strokePath()
        
        // Label the axes
        labelAxes(rect: rect)
    }
    
    private func labelAxes(rect: CGRect) {
        let xAxisLabel = UILabel(frame: CGRect(x: rect.size.width - 15, y: rect.midY - 20, width: 20, height: 20))
        xAxisLabel.text = "X"
        xAxisLabel.textColor = axisColor
        xAxisLabel.font = UIFont.boldSystemFont(ofSize: 14)
        self.addSubview(xAxisLabel)
        
        let yAxisLabel = UILabel(frame: CGRect(x: rect.midX + 10, y: 10, width: 20, height: 20))
        yAxisLabel.text = "Y"
        yAxisLabel.textColor = axisColor
        yAxisLabel.font = UIFont.boldSystemFont(ofSize: 14)
        self.addSubview(yAxisLabel)
    }
}
