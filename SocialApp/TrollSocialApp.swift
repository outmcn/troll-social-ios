import SwiftUI

@main
struct TrollSocialApp: App {
    @StateObject private var store = SocialStore()
    var body: some Scene {
        WindowGroup { RootView().environmentObject(store) }
    }
}

struct SocialStore: ObservableObject {
    @Published var selectedTab = 0
    @Published var posts: [Post] = Post.samples
    @Published var chats: [Chat] = Chat.samples
    @Published var showingComposer = false
    @Published var toast = ""

    func like(_ post: Post) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index].liked.toggle()
        posts[index].likes += posts[index].liked ? 1 : -1
    }
    func publish(_ text: String) {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        posts.insert(Post(author: "我", handle: "@troll_user", time: "刚刚", text: value, likes: 0, comments: 0, liked: false, accent: .orange), at: 0)
        showingComposer = false; toast = "已发布到广场"
    }
}

struct Post: Identifiable {
    let id = UUID(); var author: String; var handle: String; var time: String; var text: String
    var likes: Int; var comments: Int; var liked: Bool; var accent: Color
    static let samples = [
        Post(author: "小岛日记", handle: "@island", time: "12分钟前", text: "今天的风很温柔，适合去海边走走。", likes: 128, comments: 18, liked: false, accent: .blue),
        Post(author: "像素研究所", handle: "@pixel_lab", time: "38分钟前", text: "分享一个最近在做的小项目，欢迎大家交流想法。", likes: 86, comments: 12, liked: false, accent: .purple),
        Post(author: "晚风", handle: "@evening", time: "1小时前", text: "把普通的一天，也过得有一点期待。", likes: 52, comments: 7, liked: false, accent: .pink)
    ]
}
struct Chat: Identifiable { let id = UUID(); let name: String; let message: String; let time: String; let unread: Int
    static let samples = [Chat(name: "小岛日记", message: "周末一起去看展吗？", time: "09:42", unread: 2), Chat(name: "像素研究所", message: "文件我已经发给你了", time: "昨天", unread: 0), Chat(name: "晚风", message: "晚安，明天见", time: "周一", unread: 0)] }
