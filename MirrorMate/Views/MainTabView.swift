import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Record
            NavigationStack {
                RecordView()
            }
            .tabItem {
                Label("Record", systemImage: "video.circle.fill")
            }
            .tag(0)
            
            // Tab 2: History
            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Label("History", systemImage: "clock.arrow.circlepath")
            }
            .tag(1)
            
            // Tab 3: Profile
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.circle.fill")
            }
            .tag(2)
        }
        .tint(AppTheme.Colors.primary)
        .onChange(of: selectedTab) { _, _ in
            // Haptic feedback on tab switch
            HapticFeedback.selection.trigger()
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthService.shared)
}

