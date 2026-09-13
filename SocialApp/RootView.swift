import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: SocialStore
    var body: some View {
        VStack(spacing: 0) {
            screen
            SocialTabBar()
        }
        .sheet(isPresented: $store.showingComposer) {
            ComposerView().environmentObject(store)
        }
    }

    private var screen: AnyView {
        switch store.selectedTab {
        case 0: return AnyView(HomeTab())
        case 1: return AnyView(PlazaTab())
        case 3: return AnyView(ChatTab())
        default: return AnyView(MeTab())
        }
    }
}

struct SocialTabBar: View {
    @EnvironmentObject var store: SocialStore
    var body: some View {
        HStack {
            nav("house.fill", "主页", 0)
            nav("square.grid.2x2.fill", "广场", 1)
            Button { store.showingComposer = true } label: {
                Image(systemName: "plus").font(.title2.bold()).foregroundColor(.white)
                    .frame(width: 52, height: 52).background(Color.orange).clipShape(Circle())
            }
            .frame(maxWidth: .infinity)
            nav("bubble.left.and.bubble.right.fill", "聊天", 3)
            nav("person.fill", "我的", 4)
        }
        .padding(.horizontal, 8).padding(.top, 8).padding(.bottom, 6)
        .background(.ultraThinMaterial)
    }
    private func nav(_ icon: String, _ title: String, _ index: Int) -> some View {
        Button { store.selectedTab = index } label: {
            VStack(spacing: 4) { Image(systemName: icon); Text(title).font(.caption2) }
                .foregroundColor(store.selectedTab == index ? .orange : .secondary)
                .frame(maxWidth: .infinity)
        }
    }
}

struct Header: View {
    let title: String
    let subtitle: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 29, weight: .bold))
            if let subtitle = subtitle { Text(subtitle).font(.subheadline).foregroundColor(.secondary) }
        }
    }
}

struct HomeTab: View {
    @EnvironmentObject var store: SocialStore
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Header(title: "早上好，林檎", subtitle: "记录生活，也看看朋友们的近况")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(["我的动态", "小岛日记", "像素研究所", "晚风"], id: \.self) { name in
                                VStack(spacing: 6) {
                                    Circle().fill(.orange.opacity(0.2)).frame(width: 58, height: 58)
                                        .overlay(Text(name.prefix(1)).font(.title2.bold()).foregroundColor(.orange))
                                    Text(name).font(.caption)
                                }
                            }
                        }
                    }
                    Text("为你推荐").font(.headline)
                    ForEach(Array(store.posts.prefix(2))) { post in PostCard(post: post) }
                }.padding(18).padding(.bottom, 20)
            }
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Image(systemName: "bell") } }
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct PlazaTab: View {
    @EnvironmentObject var store: SocialStore
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack { Text("广场").font(.system(size: 29, weight: .bold)); Spacer(); Image(systemName: "magnifyingglass") }
                    Text("发现大家正在分享的内容").foregroundColor(.secondary)
                    HStack {
                        ForEach(["推荐", "关注", "生活", "兴趣"], id: \.self) { item in
                            Text(item).font(.caption.bold()).padding(.horizontal, 13).padding(.vertical, 8)
                                .background(item == "推荐" ? Color.orange : Color.white)
                                .foregroundColor(item == "推荐" ? .white : .secondary).clipShape(Capsule())
                        }
                    }
                    ForEach(store.posts) { post in PostCard(post: post) }
                }.padding(18).padding(.bottom, 20)
            }.background(Color(.systemGroupedBackground))
        }
    }
}

struct PostCard: View {
    @EnvironmentObject var store: SocialStore
    let post: Post
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle().fill(post.accent.opacity(0.2)).frame(width: 42, height: 42)
                    .overlay(Text(post.author.prefix(1)).bold().foregroundColor(post.accent))
                VStack(alignment: .leading) {
                    Text(post.author).bold()
                    Text("\(post.handle) · \(post.time)").font(.caption).foregroundColor(.secondary)
                }
                Spacer(); Image(systemName: "ellipsis").foregroundColor(.secondary)
            }
            Text(post.text).font(.body)
            HStack(spacing: 24) {
                Button { store.like(post) } label: {
                    Label("\(post.likes)", systemImage: post.liked ? "heart.fill" : "heart")
                }.foregroundColor(post.liked ? .pink : .secondary)
                Label("\(post.comments)", systemImage: "message")
                Label("分享", systemImage: "arrowshape.turn.up.right")
            }.font(.caption).foregroundColor(.secondary)
        }
        .padding(15).background(.white).clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
