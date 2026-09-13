import SwiftUI

struct AvatarOption: Identifiable {
    let id: String
    let symbol: String
    let color: Color
    static let all: [AvatarOption] = [
        AvatarOption(id: "sun", symbol: "☀️", color: .orange),
        AvatarOption(id: "moon", symbol: "🌙", color: .indigo),
        AvatarOption(id: "star", symbol: "⭐️", color: .yellow),
        AvatarOption(id: "cloud", symbol: "☁️", color: .blue),
        AvatarOption(id: "flower", symbol: "🌸", color: .pink),
        AvatarOption(id: "leaf", symbol: "🍃", color: .green),
        AvatarOption(id: "coffee", symbol: "☕️", color: .brown),
        AvatarOption(id: "music", symbol: "🎵", color: .purple),
        AvatarOption(id: "camera", symbol: "📷", color: .teal),
        AvatarOption(id: "heart", symbol: "❤️", color: .red)
    ]
}

struct ProfileView: View {
    @EnvironmentObject var store: SocialStore
    @State private var username = ""
    @State private var bio = ""
    @State private var avatar = "sun"
    @State private var message = ""
    @State private var saving = false

    private var currentAvatar: AvatarOption { AvatarOption.all.first { $0.id == avatar } ?? AvatarOption.all[0] }

    var body: some View {
        Form {
            Section("选择头像") {
                HStack {
                    Circle().fill(currentAvatar.color.opacity(0.18)).frame(width: 76, height: 76)
                        .overlay(Text(currentAvatar.symbol).font(.system(size: 38)))
                    Text("选择一个喜欢的头像").foregroundColor(.secondary)
                }
                VStack(spacing: 12) {
                    ForEach(0..<2, id: \.self) { row in
                        HStack(spacing: 12) {
                            ForEach(0..<5, id: \.self) { column in
                                let index = row * 5 + column
                                avatarButton(AvatarOption.all[index])
                            }
                        }
                    }
                }
                .padding(.vertical, 6)
            }
            Section("个人资料") {
                TextField("用户名", text: $username).textInputAutocapitalization(.never).autocorrectionDisabled()
                TextField("个人简介", text: $bio, axis: .vertical).lineLimit(3...5)
            }
            if !message.isEmpty { Section { Text(message).foregroundColor(.orange) } }
            Section {
                Button(saving ? "保存中..." : "保存资料") {
                    saving = true
                    Task {
                        let ok = await store.updateProfile(username: username, bio: bio, avatar: avatar)
                        message = ok ? "资料已保存" : store.toast
                        saving = false
                    }
                }.disabled(saving || username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationTitle("编辑资料")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            username = store.user?.username ?? ""
            bio = store.user?.bio ?? ""
            avatar = AvatarOption.all.contains { $0.id == store.user?.avatar } ? (store.user?.avatar ?? "sun") : "sun"
        }
    }

    private func avatarButton(_ option: AvatarOption) -> some View {
        Button {
            avatar = option.id
            message = "已选择\(option.symbol)"
        } label: {
            Text(option.symbol)
                .font(.system(size: 25))
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(option.color.opacity(avatar == option.id ? 0.35 : 0.14))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(avatar == option.id ? option.color : .clear, lineWidth: 2.5))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("选择头像\(option.id)")
    }
}

struct ChangePasswordView: View {
    @EnvironmentObject var store: SocialStore
    @State private var oldPassword = ""
    @State private var newPassword = ""
    @State private var confirm = ""
    @State private var message = ""
    var body: some View {
        Form {
            Section("修改密码") {
                SecureField("当前密码", text: $oldPassword)
                SecureField("新密码（至少 8 位）", text: $newPassword)
                SecureField("确认新密码", text: $confirm)
            }
            if !message.isEmpty { Text(message).foregroundColor(.orange) }
            Button("保存新密码") {
                Task {
                    guard newPassword == confirm else { message = "两次输入的新密码不一致"; return }
                    let ok = await store.changePassword(oldPassword: oldPassword, newPassword: newPassword)
                    message = ok ? "密码已修改，请重新登录" : store.toast
                    if ok { store.logout() }
                }
            }.disabled(oldPassword.isEmpty || newPassword.count < 8 || confirm.isEmpty)
        }.navigationTitle("修改密码").navigationBarTitleDisplayMode(.inline)
    }
}
