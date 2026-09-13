import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: SocialStore
    var body: some View {
        Group {
            if store.user == nil { AuthView() }
            else { mainView }
        }
        .sheet(isPresented: $store.showingComposer) { ComposerView().environmentObject(store) }
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
            .padding(18).background(Color(.secondarySystemBackground)).clipShape(RoundedRectangle(cornerRadius: 18))
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
            Button { store.showingComposer = true } label: { Image(systemName: "plus").font(.title2.bold()).foregroundColor(.white).frame(width: 52, height: 52).background(Color.orange).clipShape(Circle()) }.frame(maxWidth: .infinity)
            nav("bubble.left.and.bubble.right.fill", "聊天", 3); nav("person.fill", "我的", 4)
        }.padding(.horizontal, 8).padding(.top, 8).padding(.bottom, 6).background(.regularMaterial)
    }
    private func nav(_ icon: String, _ title: String, _ index: Int) -> some View { Button { store.selectedTab = index } label: { VStack(spacing: 4) { Image(systemName: icon); Text(title).font(.caption2) }.foregroundColor(store.selectedTab == index ? .orange : .secondary).frame(maxWidth: .infinity) } }
}

struct Header: View { let title: String; let subtitle: String?; var body: some View { VStack(alignment: .leading, spacing: 5) { Text(title).font(.system(size: 29, weight: .bold)); if let subtitle = subtitle { Text(subtitle).font(.subheadline).foregroundColor(.secondary) } } } }

struct HomeTab: View {
    @EnvironmentObject var store: SocialStore
    var body: some View { NavigationStack { ScrollView { VStack(alignment: .leading, spacing: 18) { Header(title: "早上好，\(store.user?.username ?? "朋友")", subtitle: "记录生活，也看看朋友们的近况"); StoryRow(); Text("为你推荐").font(.headline); ForEach(Array(store.posts.prefix(2))) { post in PostCard(post: post) } }.padding(18) }.toolbar { ToolbarItem(placement: .topBarTrailing) { Image(systemName: "bell") } }.background(Color(.systemGroupedBackground)) } }
}
struct StoryRow: View { var body: some View { ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 14) { ForEach(["我的动态", "小岛日记", "像素研究所", "晚风"], id: \.self) { name in VStack(spacing: 6) { Circle().fill(.orange.opacity(0.2)).frame(width: 58, height: 58).overlay(Text(name.prefix(1)).font(.title2.bold()).foregroundColor(.orange)); Text(name).font(.caption) } } } } } }
struct PlazaTab: View { @EnvironmentObject var store: SocialStore; var body: some View { NavigationStack { ScrollView { VStack(alignment: .leading, spacing: 14) { HStack { Text("广场").font(.system(size: 29, weight: .bold)); Spacer(); Image(systemName: "magnifyingglass") }; Text("发现大家正在分享的内容").foregroundColor(.secondary); FilterRow(); ForEach(store.posts) { post in PostCard(post: post) } }.padding(18) }.background(Color(.systemGroupedBackground)) } } }
struct FilterRow: View { var body: some View { HStack { ForEach(["推荐", "关注", "生活", "兴趣"], id: \.self) { item in Text(item).font(.caption.bold()).padding(.horizontal, 13).padding(.vertical, 8).background(item == "推荐" ? Color.orange : Color(.secondarySystemBackground)).foregroundColor(item == "推荐" ? .white : .secondary).clipShape(Capsule()) } } } }
struct PostCard: View { @EnvironmentObject var store: SocialStore; let post: Post; var body: some View { VStack(alignment: .leading, spacing: 12) { HStack { Circle().fill(post.accent.opacity(0.2)).frame(width: 42, height: 42).overlay(Text(post.author.prefix(1)).bold().foregroundColor(post.accent)); VStack(alignment: .leading) { Text(post.author).bold(); Text("\(post.handle) · \(post.time)").font(.caption).foregroundColor(.secondary) }; Spacer(); Image(systemName: "ellipsis").foregroundColor(.secondary) }; Text(post.text); HStack(spacing: 24) { Button { store.like(post) } label: { Label("\(post.likes)", systemImage: post.liked ? "heart.fill" : "heart") }.foregroundColor(post.liked ? .pink : .secondary); Label("\(post.comments)", systemImage: "message"); Label("分享", systemImage: "arrowshape.turn.up.right") }.font(.caption).foregroundColor(.secondary) }.padding(15).background(.white).clipShape(RoundedRectangle(cornerRadius: 18)) } }
