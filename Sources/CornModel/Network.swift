public enum Network {
    
    case main, test, regTest, sigNet
    
    public var bech32HRP: String {
        self == .main ? "bc" : "bcrt"
    }
}
