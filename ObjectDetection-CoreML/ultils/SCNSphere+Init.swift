//
//  SCNSphere+Init.swift
//  ObjectDetection-CoreML
//
//  Created by Huy Dang on 7/7/24.
//  Copyright © 2024 tucan9389. All rights reserved.
//

import Foundation
import SceneKit

extension SCNSphere {
    convenience init(color: UIColor, radius: CGFloat) {
        self.init(radius: radius)
        
        let material = SCNMaterial()
        material.diffuse.contents = color
        materials = [material]
    }
}
