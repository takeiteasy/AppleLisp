import JavaScriptCore

public protocol NativeAPIProvider {
    static var apiName: String { get }
    static func install(in context: JSContext) -> JSValue
}
