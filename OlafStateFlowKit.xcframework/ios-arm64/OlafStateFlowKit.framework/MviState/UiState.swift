public enum UiState<Data> {
    case initial
    case loading
    case success(value: Data)
    case empty
    case businessError(code: String, message: String)
    case systemError(code: String, message: String)
    
    // Computed properties
    public var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
    
    public var isEmpty: Bool {
        if case .empty = self { return true }
        return false
    }
    
    public var isError: Bool {
        switch self {
        case .businessError, .systemError:
            return true
        default:
            return false
        }
    }
    
    public var result: Data? {
        if case .success(let data) = self {
            return data
        }
        return nil
    }
    
    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    public var errorMessage: String? {
        switch self {
        case .businessError(_, let message):
            return message
        case .systemError(_, let message):
            return message
        default:
            return nil
        }
    }
    
    public var errorCode: String? {
        switch self {
        case .businessError(let code, _):
            return code
        case .systemError(let code, _):
            return code
        default:
            return nil
        }
    }
}
