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
    @Published var favorites: Set<UUID> = []
    @Published var showComposer = false
    @Published var selectedPost: Post?
    @Published var toast = ""
    @Published var user: User?
    @Published var isLoading = false
    @Published var sessionChecked = false
    let api = APIClient(baseURL: APIClient.officialBaseURL)
    private let tokenKey = "trollsocial.auth.token"

    init() { Task { await restoreSession() } }
    var token: String? { UserDefaults.standard.string(forKey: tokenKey) }
    func restoreSession() async {
        guard let token else { sessionChecked = true; return }
        do { let response: SessionResponse = try await api.session(token: token); user = response.user; sessionChecked = true; await loadContent() }
        catch { logout() }
        sessionChecked = true
    }
    func login(username: String, password: String) async -> Bool {
        do { let response = try await api.login(username: username, password: password); UserDefaults.standard.set(response.token, forKey: tokenKey); user = response.user; await loadContent(); return true } catch { toast = error.localizedDescription; return false }
    }
    func updateProfile(displayName: String, bio: String, avatar: String, ipRegion: String) async -> Bool {
        guard let token else { return false }
        do { let response = try await api.updateProfile(displayName: displayName, bio: bio, avatar: avatar, ipRegion: ipRegion, token: token); user = response.user; toast = "资料已保存"; return true } catch { toast = error.localizedDescription; return false }
    }
    func changePassword(oldPassword: String, newPassword: String) async -> Bool {
        guard let token else { return false }
        do { let _: BasicResponse = try await api.changePassword(oldPassword: oldPassword, newPassword: newPassword, token: token); toast = "密码已修改"; return true } catch { toast = error.localizedDescription; return false }
    }
    func register(username: String, password: String) async -> Bool {
        do { let _: RegisterResponse = try await api.register(username: username, password: password); toast = "注册成功，请登录"; return true } catch { toast = error.localizedDescription; return false }
    }
    var avatarSymbol: String { AvatarOption.all.first { $0.id == user?.avatar }?.symbol ?? "☀️" }
    func logout() { UserDefaults.standard.removeObject(forKey: tokenKey); user = nil; posts = []; chats = [] }
    func loadContent() async {
        guard let token else { return }
        isLoading = true
        do {
            let result = try await api.posts(token: token)
            posts = result.posts.map { Post(remote: $0) }
            favorites = Set(posts.filter(\.favorited).map(\.id))
            let chatResult = try await api.chats(token: token)
            chats = chatResult.chats.map { Chat(remote: $0) }
        } catch { toast = error.localizedDescription }
        isLoading = false
    }
    func replacePost(_ remote: RemotePost, liked: Bool? = nil, favorited: Bool? = nil) {
        guard let i = posts.firstIndex(where: { $0.remoteID == remote.id }) else { return }
        posts[i] = Post(remote: remote, liked: liked ?? posts[i].liked, favorite: favorited ?? posts[i].favorited)
    }
    func like(_ post: Post) { guard let token else { toast = "登录状态已失效，请重新登录"; return }; Task { @MainActor in do { let result = try await api.like(postID: post.remoteID, token: token); replacePost(result.post, liked: result.liked ?? !post.liked); } catch { toast = "点赞失败：\(error.localizedDescription)" } } }
    func publish(_ text: String) { guard let token else { return }; let value = text.trimmingCharacters(in: .whitespacesAndNewlines); guard !value.isEmpty else { return }; Task { do { let result = try await api.publish(text: value, token: token); posts.insert(Post(remote: result.post), at: 0); showComposer = false; toast = "已发布到广场" } catch { toast = error.localizedDescription } } }
    func comment(_ post: Post, text: String, completion: @escaping ([Comment]) -> Void) { guard let token else { toast = "登录状态已失效，请重新登录"; return }; let value = text.trimmingCharacters(in: .whitespacesAndNewlines); guard !value.isEmpty else { return }; Task { @MainActor in do { let result = try await api.comment(postID: post.remoteID, text: value, token: token); replacePost(result.post, liked: post.liked, favorited: post.favorited); let resultComments = try await api.comments(postID: post.remoteID, token: token); completion(resultComments.comments.map { Comment(remote: $0) }) } catch { toast = "评论失败：\(error.localizedDescription)" } } }
    func loadComments(for post: Post) async -> [Comment] { guard let token else { return [] }; do { let result = try await api.comments(postID: post.remoteID, token: token); return result.comments.map { Comment(remote: $0) } } catch { toast = error.localizedDescription; return [] } }
    func favorite(_ post: Post) { guard let token else { toast = "登录状态已失效，请重新登录"; return }; Task { @MainActor in do { let result = try await api.favorite(postID: post.remoteID, token: token); let adding = result.favorited ?? !favorites.contains(post.id); replacePost(result.post, liked: post.liked, favorited: adding); if adding { favorites.insert(post.id) } else { favorites.remove(post.id) } } catch { toast = "收藏失败：\(error.localizedDescription)" } } }
    func delete(_ post: Post) {
        guard let token else { toast = "登录状态已失效，请重新登录"; return }
        Task { @MainActor in
            do {
                let _: BasicResponse = try await api.deletePost(postID: post.remoteID, token: token)
                posts.removeAll { $0.id.uuidString.lowercased() == post.id.uuidString.lowercased() }
                favorites.remove(post.id)
                selectedPost = nil
                toast = "动态已删除"
            } catch { toast = "删除失败：\(error.localizedDescription)" }
        }
    }
}

struct Post: Identifiable { let id: UUID; let remoteID: String; var author: String; var handle: String; var authorID: String; var ipRegion: String; var time: String; var text: String; var likes: Int; var comments: Int; var favorites: Int; var liked: Bool; var favorited: Bool; var accent: Color
    init(remote: RemotePost, liked: Bool? = nil, favorite: Bool? = nil) { remoteID = remote.id; id = UUID(uuidString: remote.id) ?? UUID(); author = remote.author; handle = remote.handle; authorID = remote.authorID; ipRegion = remote.ipRegion; time = "刚刚"; text = remote.text; likes = remote.likes; comments = remote.comments; favorites = remote.favorites; self.liked = liked ?? remote.liked; favorited = favorite ?? remote.favorited; accent = .orange }
}

struct Comment: Identifiable { let id: String; let authorID: String; let text: String; let time: String
    init(remote: RemoteComment) { id = remote.id; authorID = remote.authorID; text = remote.text; time = "刚刚" }
}
struct Chat: Identifiable { let id: UUID; let name: String; let message: String; let time: String; let unread: Int
    init(remote: RemoteChat) { id = UUID(uuidString: remote.id) ?? UUID(); name = remote.name; message = remote.message; time = remote.time; unread = remote.unread }
}
