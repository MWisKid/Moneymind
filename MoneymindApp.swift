//
//  MoneymindApp.swift
//  Moneymind
//
//  Created by Micah Wisniewski on 4/9/25.
//

import SwiftUI
import SwiftData

@main
struct MoneymindApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AuthViewModel())
        }
        .modelContainer(sharedModelContainer)
    }
}

