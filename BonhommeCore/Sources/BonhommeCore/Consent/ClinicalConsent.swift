import Foundation

// MARK: - Consent Model

/// Explicit opt-in for reading clinical / medication records (HealthKit health records, CareKit med tasks).
/// Privacy-first: no clinical read is legal in-app without `isGranted == true` for the current policy version.
public struct ClinicalConsent: Codable, Sendable, Equatable {
    /// Semantic version of the consent policy text the user accepted.
    /// Bump when privacy copy or data uses change; older grants become invalid until re-accepted.
    public static let currentPolicyVersion = "1.0"

    public var isGranted: Bool
    public var grantedAt: Date?
    public var revokedAt: Date?
    /// Policy version active when the user last granted consent.
    public var policyVersion: String?

    public init(
        isGranted: Bool = false,
        grantedAt: Date? = nil,
        revokedAt: Date? = nil,
        policyVersion: String? = nil
    ) {
        self.isGranted = isGranted
        self.grantedAt = grantedAt
        self.revokedAt = revokedAt
        self.policyVersion = policyVersion
    }

    /// True only when granted under the *current* policy version.
    public var isValidForCurrentPolicy: Bool {
        isGranted && policyVersion == Self.currentPolicyVersion
    }
}

// MARK: - Audit Entry

/// Append-only audit line for consent grant / revoke (and related clinical access events).
public struct ConsentAuditEntry: Codable, Sendable, Equatable, Identifiable {
    public var id: String { "\(timestamp.timeIntervalSince1970)-\(action.rawValue)-\(detail.hashValue)" }

    public enum Action: String, Codable, Sendable {
        case grant
        case revoke
        case clinicalReadAttempt
        case clinicalReadBlocked
        case clinicalReadSuccess
        case clinicalReadFailure
        case careKitSync
        case manualEntry
    }

    public let timestamp: Date
    public let action: Action
    /// Human-readable detail (no PHI — medication names should not appear here).
    public let detail: String

    public init(timestamp: Date = Date(), action: Action, detail: String) {
        self.timestamp = timestamp
        self.action = action
        self.detail = detail
    }

    /// Single-line audit string suitable for logs / support export.
    public var auditString: String {
        let iso = ISO8601DateFormatter().string(from: timestamp)
        return "[\(iso)] consent.\(action.rawValue): \(detail)"
    }
}

// MARK: - Consent Store

/// Lightweight UserDefaults-backed store for clinical medication consent.
/// Independent of SwiftData so the gate works before ModelContainer is ready.
public final class ConsentStore: @unchecked Sendable {
    public static let shared = ConsentStore()

    private let defaults: UserDefaults
    private let consentKey = "natural.clinicalConsent.v1"
    private let auditKey = "natural.clinicalConsent.audit.v1"
    private let maxAuditEntries = 100
    private let lock = NSLock()

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: Read

    public var consent: ClinicalConsent {
        lock.lock()
        defer { lock.unlock() }
        guard let data = defaults.data(forKey: consentKey),
              let decoded = try? JSONDecoder().decode(ClinicalConsent.self, from: data) else {
            return ClinicalConsent()
        }
        return decoded
    }

    /// Convenience: valid explicit consent for clinical / medication reads.
    public var hasValidClinicalConsent: Bool {
        consent.isValidForCurrentPolicy
    }

    public var auditLog: [ConsentAuditEntry] {
        lock.lock()
        defer { lock.unlock() }
        return loadAuditUnlocked()
    }

    // MARK: Mutate

    /// Grants consent for the current policy version and appends an audit entry.
    @discardableResult
    public func grant(at date: Date = Date()) -> ClinicalConsent {
        lock.lock()
        defer { lock.unlock() }
        let updated = ClinicalConsent(
            isGranted: true,
            grantedAt: date,
            revokedAt: nil,
            policyVersion: ClinicalConsent.currentPolicyVersion
        )
        persistUnlocked(updated)
        appendAuditUnlocked(ConsentAuditEntry(
            timestamp: date,
            action: .grant,
            detail: "user_opt_in policy=\(ClinicalConsent.currentPolicyVersion)"
        ))
        return updated
    }

    /// Revokes consent and appends an audit entry. Callers must stop clinical reads immediately.
    @discardableResult
    public func revoke(at date: Date = Date()) -> ClinicalConsent {
        lock.lock()
        defer { lock.unlock() }
        let previous = loadConsentUnlocked()
        let updated = ClinicalConsent(
            isGranted: false,
            grantedAt: previous.grantedAt,
            revokedAt: date,
            policyVersion: previous.policyVersion
        )
        persistUnlocked(updated)
        appendAuditUnlocked(ConsentAuditEntry(
            timestamp: date,
            action: .revoke,
            detail: "user_opt_out previousPolicy=\(previous.policyVersion ?? "none")"
        ))
        return updated
    }

    /// Append a non-grant/revoke audit line (e.g. blocked clinical read).
    public func appendAudit(_ entry: ConsentAuditEntry) {
        lock.lock()
        defer { lock.unlock() }
        appendAuditUnlocked(entry)
    }

    /// Clears all consent + audit data (for tests / account reset).
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        defaults.removeObject(forKey: consentKey)
        defaults.removeObject(forKey: auditKey)
    }

    // MARK: Private

    private func loadConsentUnlocked() -> ClinicalConsent {
        guard let data = defaults.data(forKey: consentKey),
              let decoded = try? JSONDecoder().decode(ClinicalConsent.self, from: data) else {
            return ClinicalConsent()
        }
        return decoded
    }

    private func persistUnlocked(_ consent: ClinicalConsent) {
        if let data = try? JSONEncoder().encode(consent) {
            defaults.set(data, forKey: consentKey)
        }
    }

    private func loadAuditUnlocked() -> [ConsentAuditEntry] {
        guard let data = defaults.data(forKey: auditKey),
              let decoded = try? JSONDecoder().decode([ConsentAuditEntry].self, from: data) else {
            return []
        }
        return decoded
    }

    private func appendAuditUnlocked(_ entry: ConsentAuditEntry) {
        var log = loadAuditUnlocked()
        log.append(entry)
        if log.count > maxAuditEntries {
            log = Array(log.suffix(maxAuditEntries))
        }
        if let data = try? JSONEncoder().encode(log) {
            defaults.set(data, forKey: auditKey)
        }
        // Mirror to console for support / crash-log correlation (no PHI in detail).
        print(entry.auditString)
    }
}
