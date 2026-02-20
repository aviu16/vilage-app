import SwiftUI
import Supabase

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Initialize Supabase Client
        let supabaseURL = "https://cgqkgilsmokmulkynkpw.supabase.co" // Replace with your actual Supabase URL
        let supabaseKey = "YOUR_SUPABASE_ANON_KEY" // Replace with your actual Supabase Anon/Public key
        _ = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
        
        // Your additional setup if needed

        return true
    }
}

@main
struct VillageApp: App {
    // Register the new AppDelegate for Supabase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            HomescreenView()
        }
    }
}
