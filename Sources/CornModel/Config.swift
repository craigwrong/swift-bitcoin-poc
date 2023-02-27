struct Config {
    let isTestnet: Bool
    static let shared = Self(isTestnet: true)
}
