import SwiftUI

@main
struct Meal_PlannerApp: App {

    var body: some Scene {
        WindowGroup {
            SplashView()
                // Set the global background color for the app
                .background(Color.appBackground.ignoresSafeArea())
        }
    }
}
