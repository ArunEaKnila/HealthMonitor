//
//  AppDelegate.swift
//  HealthMonitor
//
//  Created by apple on 03/09/20.
//  Copyright © 2020 knila. All rights reserved.
//

import UIKit
import BackgroundTasks
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        print("Did we receive Remote notification \(StorageManager.tempToken)")
        StorageManager.tempToken = ""
        
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            if granted {
                print("Yay!")

                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("D'oh")
            }
        }
        UNUserNotificationCenter.current().delegate = self
        
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.knila.HealthMonitor.checkSteps",
            using: DispatchQueue.global()
        ) { (task) in
            //self.handleAppRefresh(task)
        }
        
        return true
    }
    

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // 1. Convert device token to string
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        let token = tokenParts.joined()
        
        // 2. Print device token to use for PNs payloads
        print("Device Token: \(token)")
        
        // 3. Save the token to local storeage and post to app server to generate Push Notification. ...
        StorageManager.deviceToken = token
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        print("Received push notification: \(userInfo)")
        let aps = userInfo["aps"] as! [String: Any]
        print("\(aps)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("didReceiveRemoteNotification")
        
        StorageManager.tempToken = "LAUNCHED NOTI"
        
        guard (userInfo["aps"] as? [String: AnyObject]) != nil else {
          completionHandler(.failed)
          return
        }
        
        StepCountManager.shared.getSteps { (samples) in
            guard let samples = samples, !samples.isEmpty else {
                completionHandler(.noData)
                return
            }
            
            completionHandler(.newData)
        }
    }
    
    private func handleAppRefresh(_ task: BGTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        StepCountManager.shared.getStepsFromLastChecked(task)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        print("applicationWillResignActive")
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("applicationDidEnterBackground")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("willPresent")
        completionHandler(.alert)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("didReceive")
        completionHandler()
    }
}

