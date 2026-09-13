import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var store: SocialStore
    @Environment(\.dismiss) private var dismiss
    @State private var username = ""
    @State private var bio = ""
    @State private var avatar = ""
    @State private var message = ""
    @State private var saving = false

    var body: some View {
        Form {
            Section("头像") {
                HStack {
                    Circle().fill(.orange.opacity(0.2)).frame(width: 76, height: 76)
                        .overlay(Text(avatar.isEmpty ? String(username.prefix(1)) : avatar).font(.title.bold()).foregroundColor(.orange))
                    TextField("头像文字（1个字）", text: $avatar).textFieldStyle(.roundedBorder)
                }
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
            avatar = store.user?.avatar ?? ""
        }
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
