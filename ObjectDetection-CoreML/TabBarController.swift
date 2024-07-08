//
//  TabBarController.swift
//  ObjectDetection-CoreML
//
//  Created by Huy Dang on 4/7/24.
//  Copyright © 2024 tucan9389. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController {

    override func viewDidLoad() {
            super.viewDidLoad()

            let firstVC = DetectNailViewController()
            let secondVC = DistanceViewController()

        firstVC.tabBarItem = UITabBarItem(title: "Detect Nails", image: UIImage(named: "detectIcon"), tag: 0)
        secondVC.tabBarItem = UITabBarItem(title: "Distance", image: UIImage(named: "distanceIcon"), tag: 1)

            let nav1 = UINavigationController(rootViewController: firstVC)
            let nav2 = UINavigationController(rootViewController: secondVC)

            viewControllers = [nav1, nav2]
        }
}
