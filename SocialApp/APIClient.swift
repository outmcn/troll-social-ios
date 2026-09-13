import Foundation
import SwiftUI

struct APIClient {
    static let officialBaseURL = URL(string: "https://chat.outmcn.net")!
    let baseURL: URL
    let session: URLSession

    init(baseURL: URL = APIClient.officialBaseURL) {
        self.baseURL = baseURL
        self.session = .shared
    }

    func request<T: Decodable>(_ path: String, method: String = "GET", body: Data? = nil) async throws -> T {
        let url = baseURL.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil { request.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        request.httpBody = body
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw APIError.badResponse
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    func health() async -> Bool {
        do {
            _ = try await request("api/health") as EmptyResponse
            return true
        } catch { return false }
    }
}

struct EmptyResponse: Decodable {}
enum APIError: Error { case badResponse }
