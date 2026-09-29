import Combine
import Foundation
import MacPerfMonitorCore

/// Keeps the active diagnostic check catalog up to date from our server. It fetches
/// a signed manifest, verifies its Ed25519 signature against a bundled public key,
/// caches it, and adopts it only when the signature is valid AND it is newer than
/// (or replacing) the built-in pack — otherwise it stays on the built-in pack. The
/// signature is the guarantee: a tampered server or CDN cannot push rules, because
/// the private signing key lives only on our build machine, never here.
@MainActor
final class CheckCatalogStore: ObservableObject {
    static let shared = CheckCatalogStore()

    enum Source: Sendable { case builtIn, server }

    /// The catalog the diagnostics run against right now.
    @Published private(set) var manifest: CheckManifest = CheckCatalog.builtIn
    /// Whether the active catalog came from the server (downloaded/cached) or is the
    /// app's built-in fallback.
    @Published private(set) var source: Source = .builtIn

    var version: Int { manifest.version }
    var checkCount: Int { manifest.checks.count }

    private var inFlight: Task<Void, Never>?

    init() { loadCached() }

    /// Fetch + verify + adopt, awaiting the result. Coalesces concurrent callers
    /// onto one fetch (so the launch refresh and a deep dive opened right after share
    /// the same network round-trip). Never downgrades on failure.
    func refresh() async {
        if let inFlight {
            await inFlight.value
            return
        }
        let task = Task { await self.performFetch() }
        inFlight = task
        await task.value
        inFlight = nil
    }

    /// Fire-and-forget refresh, for app launch.
    func refreshInBackground() { Task { await refresh() } }

    /// Fork: remote catalog updates are disabled, no request leaves the machine.
    /// The app keeps the built-in pack (or a copy cached by an earlier build).
    private func performFetch() async {}

    // MARK: - Cache

    private var cacheURL: URL? {
        guard
            let base = try? FileManager.default.url(
                for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil,
                create: true)
        else { return nil }
        let bundleID = Bundle.main.bundleIdentifier ?? "uk.co.bzwrd.macperfmonitor"
        return
            base
            .appendingPathComponent(bundleID, isDirectory: true)
            .appendingPathComponent("checks-manifest.json")
    }

    private func loadCached() {
        guard let url = cacheURL, let data = try? Data(contentsOf: url),
            let cached = try? JSONDecoder().decode(CheckManifest.self, from: data),
            cached.version >= CheckCatalog.builtIn.version
        else { return }
        manifest = cached
        source = .server
    }
}
