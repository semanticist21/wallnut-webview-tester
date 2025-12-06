//
//  winaApp.swift
//  wina
//
//  Created by 박지원 on 12/6/25.
//

import SwiftUI

@main
struct winaApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}
