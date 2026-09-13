import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: SocialStore
    var body: some View {
        Group {
            if !store.sessionChecked {
                ProgressView("正在恢复登录...").tint(.orange)
            } else if store.user == nil {
                AuthView()
            } else {
                mainView
            }
        }
        .preferredColorScheme(nil)
        .background(Color(.systemBackground))
        .alert("操作提示", isPresented: Binding(get: { !store.toast.isEmpty }, set: { if !$0 { store.toast = "" } })) { Button("确定") { store.toast = "" } } message: { Text(store.toast) }
        .sheet(isPresented: $store.showComposer) { ComposerView().environmentObject(store) }
    }
    private var mainView: some View {
        VStack(spacing: 0) { screenView; SocialTabBar() }
    }
    private var screenView: AnyView {
        if store.selectedTab == 0 { return AnyView(HomeTab()) }
        if store.selectedTab == 1 { return AnyView(PlazaTab()) }
        if store.selectedTab == 3 { return AnyView(ChatTab()) }
        return AnyView(MeTab())
    }
}

struct AuthView: View {
    @EnvironmentObject var store: SocialStore
    @State private var username = ""
    @State private var password = ""
    @State private var isRegister = false
    @State private var busy = false
    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "person.2.wave.2.fill").font(.system(size: 52)).foregroundColor(.orange)
            Text("TrollSocial").font(.system(size: 30, weight: .bold))
            Text(isRegister ? "创建账号" : "登录你的社交空间").foregroundColor(.secondary)
            VStack(spacing: 12) {
                TextField("账号", text: $username).textInputAutocapitalization(.never).autocorrectionDisabled().textFieldStyle(.roundedBorder)
                SecureField("密码（至少 8 位）", text: $password).textFieldStyle(.roundedBorder)
                Button(isRegister ? "注册" : "登录") {
                    busy = true
                    Task {
                        let ok = isRegister ? await store.register(username: username, password: password) : await store.login(username: username, password: password)
                        if ok && isRegister { isRegister = false; password = "" }
                        busy = false
                    }
                }.buttonStyle(.borderedProminent).tint(.orange).frame(maxWidth: .infinity).disabled(busy || username.isEmpty || password.isEmpty)
            }
            .padding(18).background(Color(.systemBackground)).clipShape(RoundedRectangle(cornerRadius: 18))
            Button(isRegister ? "已有账号？去登录" : "没有账号？立即注册") { isRegister.toggle() }.foregroundColor(.orange)
            Spacer()
            Text("API · chat.outmcn.net").font(.caption).foregroundColor(.secondary)
        }.padding(24).background(Color(.systemGroupedBackground)).alert("提示", isPresented: Binding(get: { !store.toast.isEmpty }, set: { if !$0 { store.toast = "" } })) { Button("确定") { store.toast = "" } } message: { Text(store.toast) }
    }
}

struct SocialTabBar: View {
    @EnvironmentObject var store: SocialStore
    var body: some View {
        HStack(spacing: 0) {
            nav("house.fill", "主页", 0); nav("square.grid.2x2.fill", "广场", 1)
            Button { store.showComposer = true } label: { Image(systemName: "plus").font(.title2.bold()).foregroundColor(.white).frame(width: 52, height: 52).background(Color.orange).clipShape(Circle()) }.frame(maxWidth: .infinity)
            nav("bubble.left.and.bubble.right.fill", "聊天", 3); nav("person.fill", "我的", 4)
        }.padding(.horizontal, 8).padding(.top, 8).padding(.bottom, 6).background(.regularMaterial)
    }
    private func nav(_ icon: String, _ title: String, _ index: Int) -> some View { Button { store.selectedTab = index } label: { VStack(spacing: 4) { Image(systemName: icon); Text(title).font(.caption2) }.foregroundColor(store.selectedTab == index ? .orange : .secondary).frame(maxWidth: .infinity) } }
}

struct Header: View { let title: String; let subtitle: String?; var body: some View { VStack(alignment: .leading, spacing: 5) { Text(title).font(.system(size: 29, weight: .bold)); if let subtitle = subtitle { Text(subtitle).font(.subheadline).foregroundColor(.secondary) } } } }

struct HomeTab: View {
    @EnvironmentObject var store: SocialStore
    var body: some View { NavigationStack { ScrollView { VStack(alignment: .leading, spacing: 18) { Header(title: "主页", subtitle: "记录生活，也看看朋友们的近况")
 StoryRow()
 }.padding(18) }.toolbar { ToolbarItem(placement: .topBarTrailing) { Image(systemName: "bell") } }.background(Color(.systemGroupedBackground)) } }
}
struct StoryRow: View { var body: some View { ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 14) { ForEach(["我的动态", "小岛日记", "像素研究所", "晚风"], id: \.self) { name in VStack(spacing: 6) { Circle().fill(.orange.opacity(0.2)).frame(width: 58, height: 58).overlay(Text(name.prefix(1)).font(.title2.bold()).foregroundColor(.orange)); Text(name).font(.caption) } } } } } }
struct PlazaTab: View { @EnvironmentObject var store: SocialStore; var body: some View { NavigationStack { ScrollView { VStack(alignment: .leading, spacing: 14) { HStack { Text("广场").font(.system(size: 29, weight: .bold)); Spacer(); Image(systemName: "magnifyingglass") }; Text("发现大家正在分享的内容").foregroundColor(.secondary); FilterRow(); ForEach(store.posts) { post in PostCard(post: post, allowsDelete: false, myMode: false) } }.padding(18) }.background(Color(.systemGroupedBackground)) } } }
struct FilterRow: View { var body: some View { HStack { ForEach(["推荐", "关注", "生活", "兴趣"], id: \.self) { item in Text(item).font(.caption.bold()).padding(.horizontal, 13).padding(.vertical, 8).background(item == "推荐" ? Color.orange : Color(.tertiarySystemBackground)).foregroundColor(item == "推荐" ? .white : .primary).clipShape(Capsule()) } } } }
struct PostCard: View {
    @EnvironmentObject var store: SocialStore
    let post: Post
    let allowsDelete: Bool
    let myMode: Bool
    @State private var confirmDelete = false
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { Circle().fill(post.accent.opacity(0.2)).frame(width: 42, height: 42).overlay(Text(post.author.prefix(1)).bold().foregroundColor(post.accent)); VStack(alignment: .leading, spacing: 3) { Text(post.author).bold(); HStack(spacing: 5) { Text("ID：\(post.authorID)"); if !post.ipRegion.isEmpty { Text("·"); Text(post.ipRegion) } }.font(.caption).foregroundColor(.secondary); Text(post.time).font(.caption2).foregroundColor(.secondary) }; Spacer(); if myMode { actionsMenu } }
            Text(post.text).frame(maxWidth: .infinity, alignment: .leading)
            if !myMode { Divider(); publicActions }
        }
        .padding(15).background(Color(.secondarySystemBackground)).overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(.separator).opacity(0.35), lineWidth: 0.7)).clipShape(RoundedRectangle(cornerRadius: 18))
        .sheet(item: $store.selectedPost) { selected in CommentsView(post: selected).environmentObject(store) }
        .confirmationDialog("删除这条动态？", isPresented: $confirmDelete, titleVisibility: .visible) { Button("删除", role: .destructive) { store.delete(post) }; Button("取消", role: .cancel) { } }
    }
    private var publicActions: some View { HStack(spacing: 3) {
        Button { store.like(post) } label: { Label("\(post.likes)", systemImage: post.liked ? "heart.fill" : "heart").labelStyle(.titleAndIcon).lineLimit(1).frame(width: 52, height: 25) }.buttonStyle(.plain).foregroundColor(post.liked ? .pink : .secondary)
        Button { store.favorite(post) } label: { Label("\(post.favorites)", systemImage: store.favorites.contains(post.id) ? "bookmark.fill" : "bookmark").labelStyle(.titleAndIcon).lineLimit(1).frame(width: 52, height: 25) }.buttonStyle(.plain).foregroundColor(store.favorites.contains(post.id) ? .orange : .secondary)
        Button { store.selectedPost = post } label: { Label("\(post.comments)", systemImage: "message").labelStyle(.titleAndIcon).lineLimit(1).frame(width: 52, height: 25) }.buttonStyle(.plain).foregroundColor(.secondary)
        ShareLink(item: post.text) { Image(systemName: "arrowshape.turn.up.right").frame(width: 52, height: 25) }.buttonStyle(.plain).foregroundColor(.secondary)
    }.font(.caption2).frame(maxWidth: .infinity, alignment: .center) }
    private var actionsMenu: some View { Menu { Button { store.like(post) } label: { Label(post.liked ? "取消点赞" : "点赞", systemImage: post.liked ? "heart.fill" : "heart") }; Button { store.favorite(post) } label: { Label(store.favorites.contains(post.id) ? "取消收藏" : "收藏", systemImage: store.favorites.contains(post.id) ? "bookmark.fill" : "bookmark") }; Button { store.selectedPost = post } label: { Label("评论", systemImage: "message") }; ShareLink(item: post.text) { Label("分享", systemImage: "arrowshape.turn.up.right") }; if allowsDelete { Button(role: .destructive) { confirmDelete = true } label: { Label("删除动态", systemImage: "trash") } } } label: { Image(systemName: "ellipsis").font(.headline).frame(width: 32, height: 32).contentShape(Rectangle()) }.buttonStyle(.plain).foregroundColor(.secondary) }
}

struct CommentsView: View {
    @EnvironmentObject var store: SocialStore
    @Environment(\.dismiss) private var dismiss
    let post: Post
    @State private var comments: [Comment] = []
    @State private var text = ""
    @State private var loading = true
    var body: some View {
        NavigationStack {
            VStack {
                if loading { ProgressView() }
                else if comments.isEmpty { Text("还没有评论").foregroundColor(.secondary).padding(.top, 35); Spacer() }
                else { List(comments) { c in VStack(alignment: .leading, spacing: 4) { Text("ID：\(c.authorID)").font(.caption).foregroundColor(.secondary); Text(c.text) } } }
                HStack { TextField("说点什么...", text: $text).textFieldStyle(.roundedBorder); Button { let value = text; text = ""; store.comment(post, text: value) { comments = $0 } } label: { Image(systemName: "paperplane.fill") }.buttonStyle(.borderedProminent).tint(.orange).disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }.padding()
            }.navigationTitle("评论").navigationBarTitleDisplayMode(.inline).task { comments = await store.loadComments(for: post); loading = false }
        }
    }
}
