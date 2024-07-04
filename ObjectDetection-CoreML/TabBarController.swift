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

        // Create instances of view controllers
        let firstVC = FirstViewController()
        let secondVC = SecondViewController()


        // Configure tab bar items for each view controller
        firstVC.tabBarItem = UITabBarItem(title: "First", image: UIImage(named: "firstIcon"), tag: 0)
        secondVC.tabBarItem = UITabBarItem(title: "Second", image: UIImage(named: "secondIcon"), tag: 1)

        // Wrap view controllers in navigation controllers for additional functionality
        let nav1 = UINavigationController(rootViewController: firstVC)
        let nav2 = UINavigationController(rootViewController: secondVC)

        // Assign view controllers to the tab bar
        viewControllers = [nav1, nav2]
    }
}
