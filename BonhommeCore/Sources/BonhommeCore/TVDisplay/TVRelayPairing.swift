import Foundation
import Network
import Security

/// Ephemeral, high-entropy credential carried only by the on-screen QR/manual code.
/// Never advertise the key through Bonjour or persist it in preferences/logs.
public struct TVRelayPairing: Sendable {
    public static let serviceType = "_bonhomme._tcp"
    public static let lifetime: TimeInterval = 300
    public let id: UUID
    private let secret: Data

    public enum PairingError: Error { case invalidInvitation, randomGenerationFailed }

    public static func generate() throws -> Self {
        var bytes = [UInt8](repeating: 0, count: 32)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else {
            throw PairingError.randomGenerationFailed
        }
        return Self(id: UUID(), secret: Data(bytes))
    }

    private init(id: UUID, secret: Data) { self.id = id; self.secret = secret }

    public init(id: UUID, code: String) throws {
        let code = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard code.count == 43, code.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-" || $0 == "_") }),
              let bytes = Data(base64Encoded: code.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/") + "="),
              bytes.count == 32 else { throw PairingError.invalidInvitation }
        self.init(id: id, secret: bytes)
        guard self.code == code else { throw PairingError.invalidInvitation }
    }

    public init(url: URL) throws {
        guard let parts = URLComponents(url: url, resolvingAgainstBaseURL: false),
              parts.scheme == "natural-tv", parts.host == "pair", parts.path.isEmpty,
              parts.user == nil, parts.password == nil, parts.port == nil, parts.fragment == nil,
              let items = parts.queryItems, items.count == 3,
              items.filter({ $0.name == "v" }).first?.value == "1",
              let identifier = items.first(where: { $0.name == "id" })?.value,
              let id = UUID(uuidString: identifier),
              let code = items.first(where: { $0.name == "key" })?.value else {
            throw PairingError.invalidInvitation
        }
        try self.init(id: id, code: code)
    }

    public var code: String {
        secret.base64EncodedString().replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }
    public var serviceName: String { "NATURaL-" + id.uuidString }
    public var url: URL {
        var parts = URLComponents()
        parts.scheme = "natural-tv"; parts.host = "pair"
        parts.queryItems = [URLQueryItem(name: "v", value: "1"), URLQueryItem(name: "id", value: id.uuidString), URLQueryItem(name: "key", value: code)]
        return parts.url!
    }
    public static func identifier(serviceName: String) -> UUID? {
        guard serviceName.hasPrefix("NATURaL-") else { return nil }
        return UUID(uuidString: String(serviceName.dropFirst(8)))
    }

    /// Apple's Network TLS-PSK pattern with a random 256-bit key, not a short PIN.
    /// https://developer.apple.com/documentation/network/building-a-custom-peer-to-peer-protocol
    public func parameters() -> NWParameters {
        let tls = NWProtocolTLS.Options()
        let key = secret.withUnsafeBytes { DispatchData(bytes: $0) }
        let identity = Data(id.uuidString.utf8).withUnsafeBytes { DispatchData(bytes: $0) }
        sec_protocol_options_add_pre_shared_key(tls.securityProtocolOptions, key as __DispatchData, identity as __DispatchData)
        sec_protocol_options_append_tls_ciphersuite(tls.securityProtocolOptions,
            tls_ciphersuite_t(rawValue: TLS_PSK_WITH_AES_128_GCM_SHA256)!)
        sec_protocol_options_set_min_tls_protocol_version(tls.securityProtocolOptions, .TLSv12)
        sec_protocol_options_set_max_tls_protocol_version(tls.securityProtocolOptions, .TLSv12)
        let tcp = NWProtocolTCP.Options()
        tcp.enableKeepalive = true; tcp.keepaliveIdle = 2; tcp.keepaliveInterval = 2; tcp.keepaliveCount = 3
        let parameters = NWParameters(tls: tls, tcp: tcp)
        parameters.includePeerToPeer = true
        return parameters
    }
}

public enum TVRelayClock {
    private static let origin = ContinuousClock.now
    public static var now: TimeInterval {
        let elapsed = origin.duration(to: .now).components
        return Double(elapsed.seconds) + Double(elapsed.attoseconds) / 1e18
    }
}
