import Foundation

struct LiveAPIClient: APIClient {
    // shortcut: local dev server over plain HTTP, make this a build setting and send a Referer header (Django requires it on HTTPS) before pointing at a deployed backend.
    var baseURL = URL(string: "http://127.0.0.1:8000")!
    // Ephemeral: the session cookie is gone when the app quits, so nothing is left on disk.
    var session = URLSession(configuration: .ephemeral)

    /// The backend has no JSON login, only Django's session login form, so this fetches the
    /// CSRF cookie and posts the form the same way the web frontend does.
    func login(username: String, password: String, role: UserRole) async throws {
        _ = try await session.data(from: url("login/"))

        var request = URLRequest(url: url("login/"))
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = Self.formBody([
            "csrfmiddlewaretoken": csrfToken ?? "",
            "role": role.rawValue,
            "username": username,
            "password": password,
        ])
        let (body, response) = try await session.data(for: request)

        // Success redirects to the role's dashboard page, which URLSession follows to a 200.
        switch (response as? HTTPURLResponse)?.statusCode {
        case 200: return
        case 401: throw APIError.invalidCredentials
        case 403: throw APIError.roleMismatch
        default: throw APIError.server(body: body)
        }
    }

    func logout() async throws {
        var request = URLRequest(url: url("logout/"))
        request.httpMethod = "POST"
        request.setValue(csrfToken, forHTTPHeaderField: "X-CSRFToken")
        _ = try await session.data(for: request)
    }

    func myProfessors() async throws -> [Professor] {
        try await send(URLRequest(url: url("api/professors/")))
    }

    func searchProfessors(_ query: String) async throws -> [Professor] {
        let url = url("api/professors/").appending(queryItems: [URLQueryItem(name: "search", value: query)])
        return try await send(URLRequest(url: url))
    }

    func appointments() async throws -> [Appointment] {
        try await send(URLRequest(url: url("api/appointments/")))
    }

    func book(professorID: Int, at time: Date, topic: Appointment.Topic) async throws -> Appointment {
        struct Body: Encodable {
            let professor: Int
            let appointmentTime: Date
            let topic: Appointment.Topic
        }
        return try await send(write("POST", url("api/appointments/"), Body(professor: professorID, appointmentTime: time, topic: topic)))
    }

    func cancel(appointmentID: Int) async throws -> Appointment {
        struct Body: Encodable { let status: Appointment.Status }
        return try await send(write("PATCH", url("api/appointments/\(appointmentID)/"), Body(status: .cancelled)))
    }

    // MARK: - Helpers

    /// Percent-encodes everything outside the unreserved set, so "+" and "&" in a password survive.
    static func formBody(_ fields: [String: String]) -> Data {
        let unreserved = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
        let pairs = fields.sorted { $0.key < $1.key }.map { key, value in
            "\(key)=\(value.addingPercentEncoding(withAllowedCharacters: unreserved) ?? "")"
        }
        return Data(pairs.joined(separator: "&").utf8)
    }

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private var csrfToken: String? {
        session.configuration.httpCookieStorage?.cookies(for: baseURL)?.first { $0.name == "csrftoken" }?.value
    }

    /// Built from the string because `URL.appending(path:)` turned "login/" into "/login//" on iOS 18.0,
    /// and Django's routes need exactly one trailing slash.
    func url(_ path: String) -> URL {
        URL(string: "\(baseURL.absoluteString)/\(path)")!
    }

    private func write(_ method: String, _ url: URL, _ body: some Encodable) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(csrfToken, forHTTPHeaderField: "X-CSRFToken")
        request.httpBody = try Self.encoder.encode(body)
        return request
    }

    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (body, response) = try await session.data(for: request)
        guard let status = (response as? HTTPURLResponse)?.statusCode, 200..<300 ~= status else {
            throw APIError.server(body: body)
        }
        return try Self.decoder.decode(T.self, from: body)
    }
}
