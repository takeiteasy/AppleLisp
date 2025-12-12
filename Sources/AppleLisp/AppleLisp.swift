import JavaScriptCore
import Foundation

public class AppleLisp {
    public let jsContext: JSContext
    private var context: JSContext { jsContext }  // Backward compat alias
    private let wispCompile: JSValue
    private var loadedAPIs: Set<NativeAPI> = []
    private var customAPIs: Set<String> = []
    
    public enum NativeAPI: String, CaseIterable {
        case FileManager
        case Process
        case UserDefaults
        case Workspace
        case Clipboard
        case Interaction
        case Application
        case Notification
        case UIAutomation
        case InputSimulation
        case SystemControl
        case WindowManagement
    }
    
    public enum Error: Swift.Error, LocalizedError {
        case runtimeNotFound
        case wispNotLoaded
        case compilationFailed(String)
        case evaluationFailed(String)
        case noCodeGenerated
        case unknownAPI(String)
        
        public var errorDescription: String? {
            switch self {
            case .runtimeNotFound:
                return "Could not find wisp_jsc.js runtime in bundle"
            case .wispNotLoaded:
                return "Wisp object not found in JavaScript context"
            case .compilationFailed(let msg):
                return "Compilation error: \(msg)"
            case .evaluationFailed(let msg):
                return "Evaluation error: \(msg)"
            case .noCodeGenerated:
                return "Compilation produced no output"
            case .unknownAPI(let name):
                return "Unknown native API: \(name)"
            }
        }
    }
    
    public init() throws {
        guard let context = JSContext() else {
            throw Error.runtimeNotFound
        }
        self.jsContext = context
        
        Self.setupConsole(context)
        
        guard let runtimeURL = Bundle.module.url(forResource: "wisp_jsc", withExtension: "js"),
              let runtimeCode = try? String(contentsOf: runtimeURL, encoding: .utf8) else {
            throw Error.runtimeNotFound
        }
        
        context.evaluateScript(runtimeCode)
        if let exception = context.exception, !exception.isUndefined {
            throw Error.compilationFailed(exception.toString() ?? "Unknown error loading runtime")
        }
        
        guard let wisp = context.objectForKeyedSubscript("Wisp"),
              !wisp.isUndefined else {
            throw Error.wispNotLoaded
        }
        
        guard let compile = wisp.objectForKeyedSubscript("compile"),
              !compile.isUndefined else {
            throw Error.wispNotLoaded
        }
        self.wispCompile = compile
        
        Self.setupWispEnvironment(context)
        setupRequireHook()
    }
    
    // MARK: - Native API Loading
    
    @discardableResult
    public func loadAPI(_ api: NativeAPI) -> JSValue {
        if loadedAPIs.contains(api) {
            return context.objectForKeyedSubscript("__macos_apis")!
                .objectForKeyedSubscript(api.rawValue)!
        }
        
        let jsValue: JSValue
        switch api {
        case .FileManager:
            jsValue = FileManagerAPI.install(in: context)
        case .Process:
            jsValue = ProcessAPI.install(in: context)
        case .UserDefaults:
            jsValue = UserDefaultsAPI.install(in: context)
        case .Workspace:
            jsValue = WorkspaceAPI.install(in: context)
        case .Clipboard:
            jsValue = ClipboardAPI.install(in: context)
        case .Interaction:
            jsValue = InteractionAPI.install(in: context)
        case .Application:
            jsValue = ApplicationAPI.install(in: context)
        case .Notification:
            jsValue = NotificationAPI.install(in: context)
        case .UIAutomation:
            jsValue = UIAutomationAPI.install(in: context)
        case .InputSimulation:
            jsValue = InputSimulationAPI.install(in: context)
        case .SystemControl:
            jsValue = SystemControlAPI.install(in: context)
        case .WindowManagement:
            jsValue = WindowManagementAPI.install(in: context)
        }
        
        // Store in __macos_apis cache
        let apis = context.objectForKeyedSubscript("__macos_apis")!
        apis.setObject(jsValue, forKeyedSubscript: api.rawValue as NSString)
        
        loadedAPIs.insert(api)
        return jsValue
    }
    
    /// Register a custom API from external code (e.g., repl target)
    @discardableResult
    public func registerCustomAPI(name: String, value: JSValue) -> JSValue {
        let apis = context.objectForKeyedSubscript("__macos_apis")!
        apis.setObject(value, forKeyedSubscript: name as NSString)
        customAPIs.insert(name)
        return value
    }
    
    /// Check if a custom API is registered
    public func hasCustomAPI(name: String) -> Bool {
        return customAPIs.contains(name)
    }

    
    public var availableAPIs: [NativeAPI] {
        NativeAPI.allCases
    }
    
    // MARK: - Compilation & Evaluation
    
    public func compile(source: String, uri: String = "<repl>") throws -> String {
        let result = wispCompile.call(withArguments: [source, ["source-uri": uri]])
        
        if let error = result?.objectForKeyedSubscript("error"), !error.isUndefined {
            throw Error.compilationFailed(error.toString() ?? "Unknown error")
        }
        
        guard let code = result?.objectForKeyedSubscript("code")?.toString(),
              !code.isEmpty else {
            throw Error.noCodeGenerated
        }
        
        return code
    }
    
    @discardableResult
    public func evaluate(source: String, uri: String = "<repl>") throws -> JSValue? {
        let code = try compile(source: source, uri: uri)
        return try run(javascript: code)
    }
    
    @discardableResult
    public func run(javascript code: String) throws -> JSValue? {
        let result = context.evaluateScript(code)
        
        if let exception = context.exception, !exception.isUndefined {
            context.exception = nil
            throw Error.evaluationFailed(exception.toString() ?? "Unknown error")
        }
        
        return result
    }
    
    // MARK: - Private Setup Methods
    
    private static func setupConsole(_ context: JSContext) {
        let log: @convention(block) () -> Void = {
            let args = JSContext.currentArguments()
            let msg = args?.compactMap { ($0 as? JSValue)?.toString() }.joined(separator: " ") ?? ""
            print(msg)
        }
        
        let console = JSValue(newObjectIn: context)
        console?.setObject(unsafeBitCast(log, to: AnyObject.self), forKeyedSubscript: "log" as NSString)
        console?.setObject(unsafeBitCast(log, to: AnyObject.self), forKeyedSubscript: "error" as NSString)
        console?.setObject(unsafeBitCast(log, to: AnyObject.self), forKeyedSubscript: "warn" as NSString)
        context.setObject(console, forKeyedSubscript: "console" as NSString)
    }
    
    private static func setupWispEnvironment(_ context: JSContext) {
        let setupScript = """
        var runtime = Wisp.runtime;
        var sequence = Wisp.sequence;
        var string = Wisp.string;
        
        // Copy properties to global scope
        for (var key in runtime) { this[key] = runtime[key]; }
        for (var key in sequence) { this[key] = sequence[key]; }
        for (var key in string) { this[key] = string[key]; }
        
        var exports = {};
        var __macos_apis = {};
        """
        context.evaluateScript(setupScript)
    }
    
    private func setupRequireHook() {
        // Swift callback for loading native APIs
        let requireNative: @convention(block) (String) -> JSValue? = { [weak self] name in
            guard let self = self else { return nil }
            
            // First check if it's a custom-registered API
            let apis = self.context.objectForKeyedSubscript("__macos_apis")!
            if let customAPI = apis.objectForKeyedSubscript(name), !customAPI.isUndefined, !customAPI.isNull {
                return customAPI
            }
            
            // Then check built-in APIs
            guard let api = NativeAPI(rawValue: name) else {
                print("Unknown native API: \(name)")
                return nil
            }
            return self.loadAPI(api)
        }
        
        context.setObject(unsafeBitCast(requireNative, to: AnyObject.self),
                          forKeyedSubscript: "__macos_require" as NSString)
        
        // Override require to intercept macos/* imports
        let requireHook = """
        (function() {
            var _originalRequire = typeof require !== 'undefined' ? require : null;
            require = function(name) {
                if (typeof name === 'string' && name.indexOf('macos/') === 0) {
                    var apiName = name.substring(8);
                    var api = __macos_require(apiName);
                    if (!api) {
                        throw new Error('Unknown native API: ' + apiName);
                    }
                    return api;
                }
                if (_originalRequire) {
                    return _originalRequire(name);
                }
                throw new Error('require is not available for: ' + name);
            };
        })();
        """
        context.evaluateScript(requireHook)
    }
}

