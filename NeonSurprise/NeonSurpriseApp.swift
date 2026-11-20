import SwiftUI
import Foundation

@main
struct NeonSurpriseApp: App {
    @StateObject private var progressStore = NeonProgressStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(progressStore)
                .preferredColorScheme(.dark)
        }
    }
}
