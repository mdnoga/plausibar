import Foundation

struct PlausibleAPI {
    let apiKey: String
    let siteID: String
    let baseURL: URL

    func realtimeVisitors() async throws -> Int {
        var comps = URLComponents(
            url: baseURL.appendingPathComponent("/api/v1/stats/realtime/visitors"),
            resolvingAgainstBaseURL: false
        )!
        comps.queryItems = [URLQueryItem(name: "site_id", value: siteID)]
        let data = try await send(comps.url!)
        guard
            let raw = String(data: data, encoding: .utf8),
            let n = Int(raw.trimmingCharacters(in: .whitespacesAndNewlines))
        else {
            throw APIError.decode(String(data: data, encoding: .utf8) ?? "")
        }
        return n
    }

    struct Aggregate: Decodable {
        let visitors: Metric?
        let pageviews: Metric?
        let bounce_rate: Metric?
        let visit_duration: Metric?
        struct Metric: Decodable { let value: Double }
    }

    func todayAggregate() async throws -> Aggregate {
        var comps = URLComponents(
            url: baseURL.appendingPathComponent("/api/v1/stats/aggregate"),
            resolvingAgainstBaseURL: false
        )!
        comps.queryItems = [
            URLQueryItem(name: "site_id", value: siteID),
            URLQueryItem(name: "period", value: "day"),
            URLQueryItem(name: "metrics", value: "visitors,pageviews,bounce_rate,visit_duration"),
        ]
        let data = try await send(comps.url!)
        struct Wrapper: Decodable { let results: Aggregate }
        return try JSONDecoder().decode(Wrapper.self, from: data).results
    }

    private func send(_ url: URL) async throws -> Data {
        var req = URLRequest(url: url)
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode >= 400 {
            throw APIError.http(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        return data
    }

    enum APIError: LocalizedError {
        case http(Int, String)
        case decode(String)

        var errorDescription: String? {
            switch self {
            case .http(let code, let body):
                return "HTTP \(code): \(body.prefix(120))"
            case .decode(let body):
                return "Decode error: \(body.prefix(120))"
            }
        }
    }
}
