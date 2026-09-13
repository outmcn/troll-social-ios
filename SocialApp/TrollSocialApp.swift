import SwiftUI

@main
struct TrollSocialApp: App {
    @StateObject private var store = SocialStore()
    var body: some Scene { WindowGroup { RootView().environmentObject(store) } }
}

@MainActor
final class SocialStore: ObservableObject {
    @Published var selectedTab = 0
    @Published var posts: [Post] = []
    @Published var chats: [Chat] = []
    @Published var showingComposer = false
    @Published var toast = ""
    @Published var user: User?
    @Published var isLoading = false
    let api = APIClient(baseURL: APIClient.officialBaseURL)
    private let tokenKey = "trollsocial.auth.token"

    init() { Task { await restoreSession() } }
    var token: String? { UserDefaults.standard.string(forKey: tokenKey) }
    func restoreSession() async {
        guard let token else { return }
        do { let response: SessionResponse = try await api.session(token: token); user = response.user; await loadContent() }
        catch { logout() }
    }
    func login(username: String, password: String) async -> Bool {
        do { let response = try await api.login(username: username, password: password); UserDefaults.standard.set(response.token, forKey: tokenKey); user = response.user; await loadContent(); return true } catch { toast = error.localizedDescription; return false }
    }
    func register(username: String, password: String) async -> Bool {
        do { let _: RegisterResponse = try await api.register(username: username, password: password); toast = "注册成功，请登录"; return true } catch { toast = error.localizedDescription; return false }
    }
    func logout() { UserDefaults.standard.removeObject(forKey: tokenKey); user = nil; posts = []; chats = [] }
    func loadContent() async {
        guard let token else { return }
        isLoading = true
        do {
            let result = try await api.posts(token: token)
            posts = result.posts.map { Post(remote: $0) }
            let chatResult = try await api.chats(token: token)
            chats = chatResult.chats.map { Chat(remote: $0) }
        } catch { toast = error.localizedDescription }
        isLoading = false
    }
    func like(_ post: Post) { guard let token else { return }; Task { do { let result = try await api.like(postID: post.id.uuidString, token: token); if let i = posts.firstIndex(where: { $0.id == post.id }) { posts[i] = Post(remote: result.post, liked: !post.liked) } } catch { toast = error.localizedDescription } } }
    func publish(_ text: String) { guard let token else { return }; let value = text.trimmingCharacters(in: .whitespacesAndNewlines); guard !value.isEmpty else { return }; Task { do { let result = try await api.publish(text: value, token: token); posts.insert(Post(remote: result.post), at: 0); showingComposer = false; toast = "已发布到广场" } catch { toast = error.localizedDescription } } }
}

struct Post: Identifiable { let id: UUID; var author: String; var handle: String; var time: String; var text: String; var likes: Int; var comments: Int; var liked: Bool; var accent: Color
    init(remote: RemotePost, liked: Bool = false) { id = UUID(uuidString: remote.id) ?? UUID(); author = remote.author; handle = remote.handle; time = "刚刚"; text = remote.text; likes = remote.likes; comments = remote.comments; self.liked = liked; accent = .orange }
}
struct Chat: Identifiable { let id: UUID; let name: String; let message: String; let time: String; let unread: Int
    init(remote: RemoteChat) { id = UUID(uuidString: remote.id) ?? UUID(); name = remote.name; message = remote.message; time = remote.time; unread = remote.unread }
}
