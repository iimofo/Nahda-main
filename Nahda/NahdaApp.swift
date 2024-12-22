//
//  NahdaApp.swift
//  Nahda
//
//  Created by mofo on 01.12.2024.
//
import SwiftUI
import Firebase

//class AppDelegate: NSObject, UIApplicationDelegate {
//    func application(
//        _ application: UIApplication,
//        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//    ) -> Bool {
//        FirebaseApp.configure()
//        return true
//    }
//}

@main
struct NahdaApp: App {
    @StateObject var authViewModel = AuthViewModel()
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
        }
    }
}

