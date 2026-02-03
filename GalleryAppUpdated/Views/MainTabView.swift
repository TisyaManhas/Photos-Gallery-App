import SwiftUI

struct MainTabView: View {
    let user: User
    
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab Content - Simple switching without transitions
            Group {
                switch selectedTab {
                case 0:
                    SearchView(user: user)
                case 1:
                    FavoritesView(user: user)
                case 2:
                    ProfileView(user: user)
                default:
                    SearchView(user: user)
                }
            }
            
            // Floating Tab Bar
            HStack(spacing: 0) {
                TabBarItem(
                    icon: "magnifyingglass",
                    isSelected: selectedTab == 0
                ) {
                    selectedTab = 0
                }
                
                TabBarItem(
                    icon: "heart.fill",
                    isSelected: selectedTab == 1
                ) {
                    selectedTab = 1
                }
                
                TabBarItem(
                    icon: "person.fill",
                    isSelected: selectedTab == 2
                ) {
                    selectedTab = 2
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
        .ignoresSafeArea(.keyboard)
        .navigationBarBackButtonHidden(true)
    }
}

struct TabBarItem: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .frame(width: 60, height: 44)
                    .background(
                        Capsule()
                            .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                    )
                    .scaleEffect(isSelected ? 1.05 : 1.0)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeOut(duration: 0.1), value: isSelected)
    }
}
