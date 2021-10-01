//
//  AppDelegate.swift
//  JobForYou
//
//  Created by inchan on 2021/08/20.
//

import UIKit
import Firebase

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        Messaging.messaging().token { token, error in
            if let error = error {
                prettyLog(title: "Error fetching FCM registration token", value: error.localizedDescription)
            } else if let token = token {
                prettyLog(title: "FCM registration token", value: token)
            }
        }
        
        PushManager().regist()

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {

        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {

    }
}

// MARK: - Push 등록 관련
extension AppDelegate {
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        //PushManager.shared.token.setApns(token: deviceToken)
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        prettyLog(title: "APNS registration token", value: tokenString)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        prettyLog(title: "Error fetching APNS registration token", value: error.localizedDescription)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        prettyLog(title: "Did Recevie Remote Notification", value: "\(userInfo)")
        completionHandler(.newData)
    }
}


extension AppDelegate: MessagingDelegate {
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        prettyLog(title: "Firebase registration token", value: fcmToken)
    }
}

class PushManager {
   
   // MARK: -
   // MARK: Regist
   
   func regist() {
       authorization { (result) in
           UIApplication.shared.registerForRemoteNotifications()
       }
   }

   func authorization(completion: @escaping (Bool) -> ()) {
       UNUserNotificationCenter
        .current()
        .requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("error: \(error)")
                }
                completion(granted)
            }
       }
   }
}
