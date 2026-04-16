import Foundation
import SwiftUI

@MainActor
final class StatsStore: ObservableObject {
    @Published var realtime: Int?
    @Published var todayVisitors: Int?
    @Published var todayPageviews: Int?
    @Published var bounceRate: Double?
    @Published var visitDuration: Double?
    @Published var lastUpdated: Date?
    @Published var errorMessage: String?
    @Published var isLoading = false

    private var timer: Timer?

    var siteID: String { UserDefaults.standard.string(forKey: "siteID") ?? "" }
    var baseURL: String { UserDefaults.standard.string(forKey: "baseURL") ?? "https://plausible.io" }
    var refreshSeconds: Int {
        let v = UserDefaults.standard.integer(forKey: "refreshSeconds")
        return v == 0 ? 30 : v
    }

    func start() {
        timer?.invalidate()
        Task { await refresh() }
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(refreshSeconds), repeats: true) { [weak self] _ in
            Task { await self?.refresh() }
        }
    }

    func refresh() async {
        guard
            let key = Keychain.load(), !key.isEmpty,
            !siteID.isEmpty,
            let url = URL(string: baseURL)
        else {
            errorMessage = "Set API key and site ID in Settings."
            return
        }
        let api = PlausibleAPI(apiKey: key, siteID: siteID, baseURL: url)
        isLoading = true
        defer { isLoading = false }
        do {
            async let rt = api.realtimeVisitors()
            async let agg = api.todayAggregate()
            let (rtValue, aggValue) = try await (rt, agg)
            realtime = rtValue
            todayVisitors = aggValue.visitors.map { Int($0.value) }
            todayPageviews = aggValue.pageviews.map { Int($0.value) }
            bounceRate = aggValue.bounce_rate?.value
            visitDuration = aggValue.visit_duration?.value
            lastUpdated = Date()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
