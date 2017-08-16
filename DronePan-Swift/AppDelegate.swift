//
//  AppDelegate.swift
//  DronePan-Swift
//
//  Created by Dennis Baldwin on 5/19/17.
//  Copyright © 2017 Unmanned Airlines, LLC. All rights reserved.
//

import UIKit
import GoogleMaps
import FirebaseCore
import FirebaseAuth
import FirebaseDatabase
import GoogleSignIn
import FBSDKCoreKit
import FBSDKLoginKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    //for keep photo count
    static var isStartingNewTaskOfPano:Bool = true
    static var totalPhotoCount:Int = 29
    static var currentPhotoCount:Int = 0
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        //Register DJI SDK
        ProductCommunicationManager.shared.registerWithSDK()
        
        //Don't let the screen sleep while app is open
        UIApplication.shared.isIdleTimerDisabled = true
        
        //FireBase
        FirebaseApp.configure()
        
        //Google Maps registration
        GMSServices.provideAPIKey("AIzaSyDwU_Twls3FwrPH5VkZv7qZ_61tWe0r6Wc")
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID

        //Firebase offline support
        Database.database().isPersistenceEnabled = true
        
        return true
    }

    
    //Google Sign In & Facebook Sign In redirection handler
    func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any])
        -> Bool {
            
            if url.absoluteString.range(of: "com.googleusercontent.apps") != nil {
                
                return GIDSignIn.sharedInstance().handle(url,
                                                         sourceApplication:options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
                                                         annotation: [:])
                
            }else{
                return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String, annotation: [:])
                
            }
            
    }

    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

