import SwiftUI

struct ChatTab: View {
    @EnvironmentObject var store: SocialStore
    var body: some View {
        NavigationStack {
            List {
                ForEach(store.chats) { chat in
                    NavigationLink {
                        ConversationView(name: chat.name)
                    } label: {
                        HStack {
                            Circle().fill(.blue.opacity(0.15)).frame(width: 48, height: 48)
                                .overlay(Text(chat.name.prefix(1)).bold().foregroundColor(.blue))
                            VStack(alignment: .leading) {
                                Text(chat.name).font(.headline)
                                Text(chat.message).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(chat.time).font(.caption2).foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("聊天")
        }
    }
}

struct ConversationView: View {
    let name: String
    @State private var text = ""
    @State private var messages = ["你好，很高兴认识你！", "最近在忙什么？"]
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(messages, id: \.self) { message in
                        Text(message)
                            .padding(11)
                            .background(Color(.systemBackground))
                            .foregroundColor(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            HStack {
                TextField("输入消息", text: $text).textFieldStyle(.roundedBorder)
                Button {
                    if !text.isEmpty { messages.append(text); text = "" }
                } label: {
                    Image(systemName: "arrow.up.circle.fill").font(.title)
                }
                .foregroundColor(.orange)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MeTab: View {
    @EnvironmentObject var store: SocialStore
    @State private var category = 0
    private let categories = ["动态", "收藏", "点赞"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    profileHeader
                    ipRegion
                    categoryPicker
                    categoryContent
                }
                .padding(18)
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("我的")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView().environmentObject(store)
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
    }

    private var profileHeader: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(.orange.opacity(0.2))
                .frame(width: 78, height: 78)
                .overlay(Text(store.avatarSymbol).font(.system(size: 36)))
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(store.user?.username ?? "未登录").font(.title2.bold())
                    NavigationLink {
                        ProfileView().environmentObject(store)
                    } label: {
                        Image(systemName: "pencil").font(.caption.bold()).foregroundColor(.orange)
                    }
                }
                Text("ID：\(store.user?.userID ?? "--------")").font(.caption).foregroundColor(.secondary)
                Text(store.user?.bio.isEmpty == false ? store.user!.bio : "分享生活，保持好奇")
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var ipRegion: some View {
        HStack {
            Image(systemName: "mappin.and.ellipse").foregroundColor(.orange)
            Text("IP属地")
            Spacer()
            Text(store.user?.ipRegion.isEmpty == false ? store.user!.ipRegion : "未知")
                .foregroundColor(.secondary)
        }
        .font(.subheadline)
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var categoryPicker: some View {
        HStack(spacing: 0) {
            ForEach(0..<categories.count, id: \.self) { index in
                Button { category = index } label: {
                    Text(categories[index]).font(.subheadline.bold())
                        .foregroundColor(category == index ? .orange : .secondary)
                        .frame(maxWidth: .infinity).padding(.vertical, 11)
                }
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 13))
    }

    private var categoryContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if category == 0 {
                if store.posts.isEmpty { EmptyCategoryView(text: "还没有发布动态") }
                else { ForEach(store.posts) { PostCard(post: $0) } }
            } else if category == 1 {
                EmptyCategoryView(text: "还没有收藏内容")
            } else {
                EmptyCategoryView(text: "还没有点赞内容")
            }
        }
    }
}

struct EmptyCategoryView: View {
    let text: String
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray").font(.system(size: 30)).foregroundColor(.secondary)
            Text(text).font(.subheadline).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 42)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct SettingsView: View {
    @EnvironmentObject var store: SocialStore
    var body: some View {
        List {
            Section("账号") {
                NavigationLink("编辑资料", destination: ProfileView().environmentObject(store))
                NavigationLink("修改密码", destination: ChangePasswordView().environmentObject(store))
            }
            Section("应用") {
                NavigationLink("账号与隐私", destination: Text("账号与隐私"))
                NavigationLink("通知设置", destination: Text("通知设置"))
                NavigationLink("关于 TrollSocial", destination: Text("关于 TrollSocial"))
            }
            Section("服务") {
                HStack { Text("官网"); Spacer(); Text("chat.outmcn.net").foregroundColor(.secondary) }
                Button("退出登录", role: .destructive) { store.logout() }
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ComposerView: View {
    @EnvironmentObject var store: SocialStore
    @Environment(\.dismiss) var dismiss
    @State private var text = ""
    var body: some View {
        NavigationStack {
            VStack {
                TextEditor(text: $text)
                    .padding(8)
                    .background(Color(.systemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                HStack {
                    Label("公开", systemImage: "globe")
                    Spacer()
                    Text("\(text.count)/500").foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .navigationTitle("发布动态")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("发布") { store.publish(text) }
                        .bold()
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
