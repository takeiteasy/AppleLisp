import JavaScriptCore
import Foundation

public struct FileManagerAPI: NativeAPIProvider {
    public static var apiName: String { "FileManager" }
    
    public static func install(in context: JSContext) -> JSValue {
        let api = JSValue(newObjectIn: context)!
        let fm = FileManager.default
        
        // exists(path) -> Bool
        let exists: @convention(block) (String) -> Bool = { path in
            fm.fileExists(atPath: path)
        }
        api.setObject(unsafeBitCast(exists, to: AnyObject.self), 
                      forKeyedSubscript: "exists" as NSString)
        
        // isDirectory(path) -> Bool
        let isDirectory: @convention(block) (String) -> Bool = { path in
            var isDir: ObjCBool = false
            fm.fileExists(atPath: path, isDirectory: &isDir)
            return isDir.boolValue
        }
        api.setObject(unsafeBitCast(isDirectory, to: AnyObject.self), 
                      forKeyedSubscript: "isDirectory" as NSString)
        
        // readFile(path) -> String | null
        let readFile: @convention(block) (String) -> String? = { path in
            try? String(contentsOfFile: path, encoding: .utf8)
        }
        api.setObject(unsafeBitCast(readFile, to: AnyObject.self), 
                      forKeyedSubscript: "readFile" as NSString)
        
        // readFileData(path) -> ArrayBuffer | null (for binary files)
        let readFileData: @convention(block) (String) -> [UInt8]? = { path in
            guard let data = fm.contents(atPath: path) else { return nil }
            return [UInt8](data)
        }
        api.setObject(unsafeBitCast(readFileData, to: AnyObject.self), 
                      forKeyedSubscript: "readFileData" as NSString)
        
        // writeFile(path, content) -> Bool
        let writeFile: @convention(block) (String, String) -> Bool = { path, content in
            do {
                try content.write(toFile: path, atomically: true, encoding: .utf8)
                return true
            } catch {
                return false
            }
        }
        api.setObject(unsafeBitCast(writeFile, to: AnyObject.self), 
                      forKeyedSubscript: "writeFile" as NSString)
        
        // listDirectory(path) -> [String] | null
        let listDirectory: @convention(block) (String) -> [String]? = { path in
            try? fm.contentsOfDirectory(atPath: path)
        }
        api.setObject(unsafeBitCast(listDirectory, to: AnyObject.self), 
                      forKeyedSubscript: "listDirectory" as NSString)
        
        // createDirectory(path) -> Bool
        let createDirectory: @convention(block) (String) -> Bool = { path in
            do {
                try fm.createDirectory(atPath: path, withIntermediateDirectories: true)
                return true
            } catch {
                return false
            }
        }
        api.setObject(unsafeBitCast(createDirectory, to: AnyObject.self), 
                      forKeyedSubscript: "createDirectory" as NSString)
        
        // remove(path) -> Bool
        let remove: @convention(block) (String) -> Bool = { path in
            do {
                try fm.removeItem(atPath: path)
                return true
            } catch {
                return false
            }
        }
        api.setObject(unsafeBitCast(remove, to: AnyObject.self), 
                      forKeyedSubscript: "remove" as NSString)
        
        // copy(src, dst) -> Bool
        let copy: @convention(block) (String, String) -> Bool = { src, dst in
            do {
                try fm.copyItem(atPath: src, toPath: dst)
                return true
            } catch {
                return false
            }
        }
        api.setObject(unsafeBitCast(copy, to: AnyObject.self), 
                      forKeyedSubscript: "copy" as NSString)
        
        // move(src, dst) -> Bool
        let move: @convention(block) (String, String) -> Bool = { src, dst in
            do {
                try fm.moveItem(atPath: src, toPath: dst)
                return true
            } catch {
                return false
            }
        }
        api.setObject(unsafeBitCast(move, to: AnyObject.self), 
                      forKeyedSubscript: "move" as NSString)
        
        // currentDirectory() -> String
        let currentDirectory: @convention(block) () -> String = {
            fm.currentDirectoryPath
        }
        api.setObject(unsafeBitCast(currentDirectory, to: AnyObject.self), 
                      forKeyedSubscript: "currentDirectory" as NSString)
        
        // homeDirectory() -> String
        let homeDirectory: @convention(block) () -> String = {
            NSHomeDirectory()
        }
        api.setObject(unsafeBitCast(homeDirectory, to: AnyObject.self), 
                      forKeyedSubscript: "homeDirectory" as NSString)
        
        // tempDirectory() -> String
        let tempDirectory: @convention(block) () -> String = {
            NSTemporaryDirectory()
        }
        api.setObject(unsafeBitCast(tempDirectory, to: AnyObject.self), 
                      forKeyedSubscript: "tempDirectory" as NSString)
        
        return api
    }
}
