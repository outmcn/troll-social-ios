import Foundation

struct APIClient {
    static let officialBaseURL = URL(string: "https://chat.outmcn.net")!
    let baseURL: URL
    func send<T: Decodable>(_ path: String, method: String = "GET", token: String? = nil, body: Data? = nil) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))))
        request.httpMethod = method; request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if body != nil { request.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        request.httpBody = body
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.badResponse }
        guard 200..<300 ~= http.statusCode else { if let e = try? JSONDecoder().decode(APIErrorResponse.self, from: data) { throw APIError.message(e.error) }; throw APIError.badResponse }
        return try JSONDecoder().decode(T.self, from: data)
    }
    func health() async -> Bool { do { let _: HealthResponse = try await send("api/health"); return true } catch { return false } }
    func login(username: String, password: String) async throws -> AuthResponse { try await send("api/auth/login", method: "POST", body: JSONEncoder().encode(Credentials(username: username, password: password))) }
    func register(username: String, password: String) async throws -> RegisterResponse { try await send("api/auth/register", method: "POST", body: JSONEncoder().encode(Credentials(username: username, password: password))) }
    func session(token: String) async throws -> SessionResponse { try await send("api/auth/me", token: token) }
    func updateProfile(displayName: String, bio: String, avatar: String, ipRegion: String, token: String) async throws -> SessionResponse { try await send("api/auth/profile", method: "PUT", token: token, body: JSONEncoder().encode(ProfileBody(displayName: displayName, bio: bio, avatar: avatar, ipRegion: ipRegion))) }
    func changePassword(oldPassword: String, newPassword: String, token: String) async throws -> BasicResponse { try await send("api/auth/password", method: "PUT", token: token, body: JSONEncoder().encode(PasswordBody(oldPassword: oldPassword, newPassword: newPassword))) }
    func posts(token: String) async throws -> PostsResponse { try await send("api/posts", token: token) }
    func publish(text: String, token: String) async throws -> SinglePostResponse { try await send("api/posts", method: "POST", token: token, body: JSONEncoder().encode(PublishBody(text: text))) }
    func like(postID: String, token: String) async throws -> SinglePostResponse { try await send("api/posts/\(postID)/like", method: "POST", token: token) }
    func comments(postID: String, token: String) async throws -> CommentsResponse { try await send("api/posts/\(postID)/comments", token: token) }
    func comment(postID: String, text: String, token: String) async throws -> SinglePostResponse { try await send("api/posts/\(postID)/comments", method: "POST", token: token, body: JSONEncoder().encode(CommentBody(text: text))) }
    func deletePost(postID: String, token: String) async throws -> BasicResponse { try await send("api/posts/\(postID)", method: "DELETE", token: token) }
}
struct Credentials: Encodable { let username: String; let password: String }
struct ProfileBody: Encodable { let displayName: String; let bio: String; let avatar: String; let ipRegion: String; enum CodingKeys: String, CodingKey { case displayName = "display_name"; case bio, avatar; case ipRegion = "ip_region" } }
struct PasswordBody: Encodable { let oldPassword: String; let newPassword: String; enum CodingKeys: String, CodingKey { case oldPassword = "old_password"; case newPassword = "new_password" } }
struct PublishBody: Encodable { let text: String }
struct CommentBody: Encodable { let text: String }
struct HealthResponse: Decodable { let ok: Bool }
struct APIErrorResponse: Decodable { let error: String }
struct BasicResponse: Decodable { let ok: Bool }
struct User: Codable { let id: String; var userID: String; var displayName: String; var username: String; var role: String; var bio: String; var avatar: String; var ipRegion: String; enum CodingKeys: String, CodingKey { case id; case userID = "user_id"; case displayName = "display_name"; case username, role, bio, avatar; case ipRegion = "ip_region" }; init(from decoder: Decoder) throws { let c = try decoder.container(keyedBy: CodingKeys.self); id = try c.decode(String.self, forKey: .id); userID = try c.decodeIfPresent(String.self, forKey: .userID) ?? ""; displayName = try c.decodeIfPresent(String.self, forKey: .displayName) ?? ""; username = try c.decodeIfPresent(String.self, forKey: .username) ?? ""; role = try c.decode(String.self, forKey: .role); bio = try c.decodeIfPresent(String.self, forKey: .bio) ?? ""; avatar = try c.decodeIfPresent(String.self, forKey: .avatar) ?? ""; ipRegion = try c.decodeIfPresent(String.self, forKey: .ipRegion) ?? "未知" } }
struct AuthResponse: Decodable { let token: String; let user: User }
struct SessionResponse: Decodable { let user: User }
struct RegisterResponse: Decodable { let user: User }
struct PostsResponse: Decodable { let posts: [RemotePost] }
struct SinglePostResponse: Decodable { let post: RemotePost }
struct CommentsResponse: Decodable { let comments: [RemoteComment] }
struct RemoteComment: Codable, Identifiable { let id: String; let authorID: String; let text: String; let createdAt: String?; enum CodingKeys: String, CodingKey { case id; case authorID = "author_id"; case text; case createdAt = "created_at" } }
struct RemotePost: Codable, Identifiable { let id: String; let author: String; let handle: String; let authorID: String; let ipRegion: String; let text: String; var likes: Int; let comments: Int; let createdAt: String?; enum CodingKeys: String, CodingKey { case id, author, handle; case authorID = "author_id"; case ipRegion = "ip_region"; case text, likes, comments; case createdAt = "created_at" }; init(from decoder: Decoder) throws { let c = try decoder.container(keyedBy: CodingKeys.self); id = try c.decode(String.self, forKey: .id); author = try c.decode(String.self, forKey: .author); handle = try c.decodeIfPresent(String.self, forKey: .handle) ?? ""; authorID = try c.decodeIfPresent(String.self, forKey: .authorID) ?? ""; ipRegion = try c.decodeIfPresent(String.self, forKey: .ipRegion) ?? ""; text = try c.decode(String.self, forKey: .text); likes = try c.decode(Int.self, forKey: .likes); comments = try c.decode(Int.self, forKey: .comments); createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt) } }
struct ChatsResponse: Decodable { let chats: [RemoteChat] }
struct RemoteChat: Codable, Identifiable { let id: String; let name: String; let message: String; let time: String; let unread: Int }
enum APIError: Error, LocalizedError { case badResponse; case message(String); var errorDescription: String? { if case .message(let value) = self { return value }; return "网络请求失败" } }
