enum Network {
    
    case main, test, regTest, sigNet
    
    var bech32HRP: String {
        self == .main ? "bc" : "bcrt"
    }
}
