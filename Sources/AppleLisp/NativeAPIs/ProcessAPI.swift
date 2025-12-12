import JavaScriptCore
import Foundation
import AppKit

public struct ProcessAPI: NativeAPIProvider {
    public static var apiName: String { "Process" }
    
    // Track spawned processes: [PID: Process]
    private static var runningProcesses: [Int32: Process] = [:]
    private static let lock = NSLock()
    
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
        
        // spawn(path, args, env?) -> Int (PID)
        let spawn: @convention(block) (String, [String]?, [String: String]?) -> Int32 = { launchPath, args, env in
            let task = Process()
            task.executableURL = URL(fileURLWithPath: launchPath)
            if let args = args { task.arguments = args }
            if let env = env { task.environment = env }
            
            // Redirect to /dev/null for now unless we implement streaming
            task.standardOutput = FileHandle.nullDevice
            task.standardError = FileHandle.nullDevice
            
            do {
                try task.run()
                ProcessAPI.lock.lock()
                ProcessAPI.runningProcesses[task.processIdentifier] = task
                ProcessAPI.lock.unlock()
                
                task.terminationHandler = { t in
                    ProcessAPI.lock.lock()
                    ProcessAPI.runningProcesses.removeValue(forKey: t.processIdentifier)
                    ProcessAPI.lock.unlock()
                }
                
                return task.processIdentifier
            } catch {
                return -1
            }
        }
        api.setObject(unsafeBitCast(spawn, to: AnyObject.self),
                      forKeyedSubscript: "spawn" as NSString)
        
        // kill(pid, signal?) -> Bool
        let kill: @convention(block) (Int32, Int32) -> Bool = { pid, signal in
            // Try to find in our managed processes first
            ProcessAPI.lock.lock()
            if let task = ProcessAPI.runningProcesses[pid] {
                task.terminate() // This sends SIGTERM usually
                ProcessAPI.lock.unlock()
                return true
            }
            ProcessAPI.lock.unlock()
            
            // Fallback to system kill for external processes
            let sig = (signal == 0) ? SIGTERM : signal
            return Darwin.kill(pid, sig) == 0
        }
        api.setObject(unsafeBitCast(kill, to: AnyObject.self),
                      forKeyedSubscript: "kill" as NSString)
        
        // launchApp(nameOrPath, options?) -> Bool
        // options: { "hide": Bool, "newInstance": Bool }
        let launchApp: @convention(block) (String, JSValue?) -> Bool = { name, options in
            let workspace = NSWorkspace.shared
            var config = NSWorkspace.OpenConfiguration()
            
            if let opts = options, opts.isObject, let dict = opts.toDictionary() as? [String: Any] {
                if let hide = dict["hide"] as? Bool, hide {
                    config.hides = true
                }
                if let newInst = dict["newInstance"] as? Bool, newInst {
                    config.createsNewApplicationInstance = true
                }
            }
            
            // Try to find url
            var url: URL?
            if name.hasPrefix("/") {
                url = URL(fileURLWithPath: name)
            } else if let appUrl = workspace.urlForApplication(withBundleIdentifier: name) {
                url = appUrl
            } else {
                 // Try finding by name
                 // Deprecated but useful fallback or using `urlForApplication(toOpen:)` equivalent?
                 // Let's assume bundle ID or full path is best.
                 // We can try to use fullPath(forApplication:) if available or URLForApplication...
                 // Re-using specific search logic might be needed but bundleID is standard.
            }
            
            guard let appUrl = url else { return false }
            
            let sema = DispatchSemaphore(value: 0)
            var success = false
            
            workspace.openApplication(at: appUrl, configuration: config) { app, error in
                success = (error == nil)
                sema.signal()
            }
            
            _ = sema.wait(timeout: .now() + 5.0)
            return success
        }
        api.setObject(unsafeBitCast(launchApp, to: AnyObject.self),
                      forKeyedSubscript: "launchApp" as NSString)
        
        return api
    }
}