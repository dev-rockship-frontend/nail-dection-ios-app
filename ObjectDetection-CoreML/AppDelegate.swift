//
//  AppDelegate.swift
//  ObjectDetection-CoreML
//
//  Created by Huy Dang on 22/6/24.
//  Copyright © 2024 tucan9389. All rights reserved.
//

//
//  AppDelegate.swift
//  ObjectDetection-CoreML
//
//  Created by Huy Dang on 22/6/24.
//  Copyright © 2024 tucan9389. All rights reserved.
//


import UIKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    //    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    //        window = UIWindow(frame: UIScreen.main.bounds)
    //
    //                // Set the TabBarController as the root view controller
    //                let tabBarController = TabBarController()
    //                window?.rootViewController = tabBarController
    //                window?.makeKeyAndVisible()
    //
    //        return true
    //    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        let mainViewController = DetectNailViewController()
        window?.rootViewController = mainViewController
        window?.makeKeyAndVisible()
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        
    }
}


