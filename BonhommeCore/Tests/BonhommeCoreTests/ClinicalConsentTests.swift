import XCTest
@testable import BonhommeCore

final class ClinicalConsentTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var store: ConsentStore!

    override func setUp() {
        super.setUp()
        suiteName = "ClinicalConsentTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        store = ConsentStore(defaults: defaults)
    }

    override func tearDown() {
        store.reset()
        defaults.removePersistentDomain(forName: suiteName)
        store = nil
        defaults = nil
        super.tearDown()
    }

    func testDefaultConsentIsNotGranted() {
        XCTAssertFalse(store.consent.isGranted)
        XCTAssertFalse(store.hasValidClinicalConsent)
        XCTAssertNil(store.consent.grantedAt)
    }

    func testGrantSetsTimestampAndVersion() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let c = store.grant(at: now)

        XCTAssertTrue(c.isGranted)
        XCTAssertEqual(c.grantedAt, now)
        XCTAssertEqual(c.policyVersion, ClinicalConsent.currentPolicyVersion)
        XCTAssertTrue(store.hasValidClinicalConsent)
        XCTAssertNil(c.revokedAt)
    }

    func testRevokeClearsValidConsent() {
        store.grant()
        XCTAssertTrue(store.hasValidClinicalConsent)

        let revokedAt = Date(timeIntervalSince1970: 1_700_000_100)
        let c = store.revoke(at: revokedAt)

        XCTAssertFalse(c.isGranted)
        XCTAssertEqual(c.revokedAt, revokedAt)
        XCTAssertFalse(store.hasValidClinicalConsent)
    }

    func testStalePolicyVersionIsInvalid() {
        // Simulate consent granted under an older policy string.
        let stale = ClinicalConsent(
            isGranted: true,
            grantedAt: Date(),
            policyVersion: "0.9"
        )
        if let data = try? JSONEncoder().encode(stale) {
            defaults.set(data, forKey: "natural.clinicalConsent.v1")
        }

        XCTAssertTrue(store.consent.isGranted)
        XCTAssertFalse(store.consent.isValidForCurrentPolicy)
        XCTAssertFalse(store.hasValidClinicalConsent)
    }

    func testAuditLogOnGrantAndRevoke() {
        store.grant()
        store.revoke()

        let actions = store.auditLog.map(\.action)
        XCTAssertEqual(actions, [.grant, .revoke])

        for entry in store.auditLog {
            XCTAssertTrue(entry.auditString.contains("consent."))
            // No PHI: detail is machine tokens only
            XCTAssertFalse(entry.detail.lowercased().contains("aspirin"))
        }
    }

    func testAppendAuditBounded() {
        for i in 0..<120 {
            store.appendAudit(ConsentAuditEntry(
                action: .clinicalReadAttempt,
                detail: "attempt_\(i)"
            ))
        }
        XCTAssertLessThanOrEqual(store.auditLog.count, 100)
    }

    func testAuditStringFormat() {
        let entry = ConsentAuditEntry(
            timestamp: Date(timeIntervalSince1970: 0),
            action: .clinicalReadBlocked,
            detail: "no_consent"
        )
        XCTAssertTrue(entry.auditString.contains("consent.clinicalReadBlocked"))
        XCTAssertTrue(entry.auditString.contains("no_consent"))
    }
}
