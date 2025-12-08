import JavaScriptCore
import Foundation

public struct ProcessAPI: NativeAPIProvider {
    public static var apiName: String { "Process" }
    
    public static func install(in context: JSContext) -> JSValue {
        let api = JSValue(newObjectIn: context)!
        let processInfo = ProcessInfo.processInfo
        
        // argv() -> [String]
        let argv: @convention(block) () -> [String] = {
            processInfo.arguments
        }
        api.setObject(unsafeBitCast(argv, to: AnyObject.self),
                      forKeyedSubscript: "argv" as NSString)
        
        // env() -> {String: String}
        let env: @convention(block) () -> [String: String] = {
            processInfo.environment
        }
        api.setObject(unsafeBitCast(env, to: AnyObject.self),
                      forKeyedSubscript: "env" as NSString)
        
        // pid() -> Int
        let pid: @convention(block) () -> Int32 = {
            processInfo.processIdentifier
        }
        api.setObject(unsafeBitCast(pid, to: AnyObject.self),
                      forKeyedSubscript: "pid" as NSString)
        
        // hostName() -> String
        let hostName: @convention(block) () -> String = {
            processInfo.hostName
        }
        api.setObject(unsafeBitCast(hostName, to: AnyObject.self),
                      forKeyedSubscript: "hostName" as NSString)
        
        // osVersion() -> String
        let osVersion: @convention(block) () -> String = {
            processInfo.operatingSystemVersionString
        }
        api.setObject(unsafeBitCast(osVersion, to: AnyObject.self),
                      forKeyedSubscript: "osVersion" as NSString)
        
        // uptime() -> Double
        let uptime: @convention(block) () -> TimeInterval = {
            processInfo.systemUptime
        }
        api.setObject(unsafeBitCast(uptime, to: AnyObject.self),
                      forKeyedSubscript: "uptime" as NSString)
        
        // exit(code)
        let exit: @convention(block) (Int32) -> Void = { code in
            Foundation.exit(code)
        }
        api.setObject(unsafeBitCast(exit, to: AnyObject.self),
                      forKeyedSubscript: "exit" as NSString)
        
        // exec(path, args, env?) -> {status: Int, stdout: String, stderr: String}
        let exec: @convention(block) (String, [String]?, [String: String]?) -> [String: Any] = { launchPath, args, env in
            let task = Process()
            task.executableURL = URL(fileURLWithPath: launchPath)
            if let args = args {
                task.arguments = args
            }
            if let env = env {
                task.environment = env
            }
            
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            task.standardOutput = stdoutPipe
            task.standardError = stderrPipe
            
            do {
                try task.run()
                task.waitUntilExit()
                
                let stdoutData = (try? stdoutPipe.fileHandleForReading.readToEnd()) ?? Data()
                let stderrData = (try? stderrPipe.fileHandleForReading.readToEnd()) ?? Data()
                
                let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
                let stderr = String(data: stderrData, encoding: .utf8) ?? ""
                
                return [
                    "status": task.terminationStatus,
                    "stdout": stdout,
                    "stderr": stderr
                ]
            } catch {
                return [
                    "status": -1,
                    "stdout": "",
                    "stderr": error.localizedDescription
                ]
            }
        }
        api.setObject(unsafeBitCast(exec, to: AnyObject.self),
                      forKeyedSubscript: "exec" as NSString)
        
        return api
    }
}
