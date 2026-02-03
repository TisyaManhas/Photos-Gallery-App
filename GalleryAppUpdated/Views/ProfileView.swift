import SwiftUI
import SwiftData

struct ProfileView: View {
    let user: User
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Custom Title
            HStack {
                Text("Profile")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)
            
            // Profile Info Row (Icon + Name + Email)
            HStack(spacing: 16) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .overlay(
                        Text(user.username.prefix(2).uppercased())
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 8, y: 3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.username)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            
            ScrollView {
                VStack(spacing: 0) {
                    
                    // Settings Section
                    VStack(spacing: 0) {
                        Text("Settings")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 12)
                        
                        VStack(spacing: 0) {
                            SettingsRow(
                                icon: "person.circle.fill",
                                iconColor: .blue,
                                title: "Edit Profile",
                                showChevron: true
                            )
                            
                            Divider()
                                .padding(.leading, 56)
                            
                            // ✅ RECENTS REMOVED HERE
                            
                            SettingsRow(
                                icon: "magnifyingglass.circle.fill",
                                iconColor: .purple,
                                title: "Search History",
                                showChevron: true
                            )
                            
                            Divider()
                                .padding(.leading, 56)
                            
                            SettingsRow(
                                icon: "bell.fill",
                                iconColor: .red,
                                title: "Notifications",
                                showChevron: true
                            )
                            
                            Divider()
                                .padding(.leading, 56)
                            
                            SettingsRow(
                                icon: "lock.fill",
                                iconColor: .indigo,
                                title: "Privacy & Security",
                                showChevron: true
                            )
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .padding(.horizontal, 20)
                        
                        // About Section
                        VStack(spacing: 0) {
                            SettingsRow(
                                icon: "info.circle.fill",
                                iconColor: .gray,
                                title: "About",
                                showChevron: true
                            )
                            
                            Divider()
                                .padding(.leading, 56)
                            
                            SettingsRow(
                                icon: "questionmark.circle.fill",
                                iconColor: .cyan,
                                title: "Help & Support",
                                showChevron: true
                            )
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    
                    // Logout Button
                    Button {
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Logout")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.red)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 40)
                    .padding(.bottom, 100)
                }
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationBarHidden(true)
    }
}

// Settings Row Component
struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let showChevron: Bool
    
    var body: some View {
        Button {
            // Action placeholder
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(iconColor)
                    )
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
