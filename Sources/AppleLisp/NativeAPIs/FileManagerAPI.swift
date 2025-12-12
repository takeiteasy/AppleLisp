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
        
        // --- New Additions ---
        
        // getAttributes(path) -> Dictionary
        let getAttributes: @convention(block) (String) -> [String: Any]? = { path in
            guard let attrs = try? fm.attributesOfItem(atPath: path) else { return nil }
            var result: [String: Any] = [:]
            
            if let size = attrs[.size] as? Int { result["size"] = size }
            if let created = attrs[.creationDate] as? Date {
                result["creationDate"] = created.timeIntervalSince1970
            }
            if let modified = attrs[.modificationDate] as? Date {
                result["modificationDate"] = modified.timeIntervalSince1970
            }
            if let type = attrs[.type] as? FileAttributeType {
                result["type"] = type.rawValue
            }
            if let perms = attrs[.posixPermissions] as? Int {
                result["permissions"] = perms
            }
            if let owner = attrs[.ownerAccountName] as? String {
                result["owner"] = owner
            }
            
            return result
        }
        api.setObject(unsafeBitCast(getAttributes, to: AnyObject.self),
                      forKeyedSubscript: "getAttributes" as NSString)
        
        // setPermissions(path, octal) -> Bool
        let setPermissions: @convention(block) (String, Int) -> Bool = { path, perms in
            do {
                try fm.setAttributes([.posixPermissions: perms], ofItemAtPath: path)
                return true
            } catch {
                return false
            }
        }
        api.setObject(unsafeBitCast(setPermissions, to: AnyObject.self),
                      forKeyedSubscript: "setPermissions" as NSString)
        
        // glob(pattern) -> [String]
        let glob: @convention(block) (String) -> [String] = { pattern in
             // Using subpaths and predicate matching for a basic "recursive glob" experience if pattern contains "/"
             // If pattern is simple "*.txt", we search current dir? Or just recursive?
             // Usually glob expands from CWD.
             // We will scan the current directory recursively and filter.
             // Warning: This can be slow for large directories.
             
             let currentDir = fm.currentDirectoryPath
             guard let enumerator = fm.enumerator(atPath: currentDir) else { return [] }
             
             let predicate = NSPredicate(format: "SELF LIKE %@", pattern)
             var results: [String] = []
             
             for case let file as String in enumerator {
                 if predicate.evaluate(with: file) {
                     results.append(file)
                 }
             }
             return results
        }
        api.setObject(unsafeBitCast(glob, to: AnyObject.self),
                      forKeyedSubscript: "glob" as NSString)

        // getXAttr(path, name) -> String?
        let getXAttr: @convention(block) (String, String) -> String? = { path, name in
            let url = URL(fileURLWithPath: path)
            return try? url.extendedAttribute(forName: name)
        }
        api.setObject(unsafeBitCast(getXAttr, to: AnyObject.self),
                      forKeyedSubscript: "getXAttr" as NSString)

        // setXAttr(path, name, value) -> Bool
        let setXAttr: @convention(block) (String, String, String) -> Bool = { path, name, value in
            let url = URL(fileURLWithPath: path)
            do {
                try url.setExtendedAttribute(data: Data(value.utf8), forName: name)
                return true
            } catch {
                return false
            }
        }
        api.setObject(unsafeBitCast(setXAttr, to: AnyObject.self),
                      forKeyedSubscript: "setXAttr" as NSString)
        
        // listXAttrs(path) -> [String]
        let listXAttrs: @convention(block) (String) -> [String] = { path in
            let url = URL(fileURLWithPath: path)
            return (try? url.listExtendedAttributes()) ?? []
        }
        api.setObject(unsafeBitCast(listXAttrs, to: AnyObject.self),
                      forKeyedSubscript: "listXAttrs" as NSString)
        
        // removeXAttr(path, name) -> Bool
        let removeXAttr: @convention(block) (String, String) -> Bool = { path, name in
            let url = URL(fileURLWithPath: path)
            do {
                try url.removeExtendedAttribute(forName: name)
                return true
            } catch {
                return false
            }
        }
        api.setObject(unsafeBitCast(removeXAttr, to: AnyObject.self),
                      forKeyedSubscript: "removeXAttr" as NSString)
        
        return api
    }
}

// MARK: - Extended Attributes Helper
// We need to implement these helpers as they are not standard on URL in pure Swift/Foundation without wrappers
extension URL {
    func extendedAttribute(forName name: String) throws -> String? {
        let data = try self.withUnsafeFileSystemRepresentation { fileSystemPath -> Data? in
            guard let fileSystemPath = fileSystemPath else { return nil }
            
            // Determine size
            let length = getxattr(fileSystemPath, name, nil, 0, 0, 0)
            if length < 0 {
                // If error is "attribute not found", return nil
                if errno == ENOATTR { return nil }
                throw URL.posixError(errno)
            }
            
            var data = Data(count: length)
            let result = data.withUnsafeMutableBytes {
                getxattr(fileSystemPath, name, $0.baseAddress, length, 0, 0)
            }
            
            if result < 0 { throw URL.posixError(errno) }
            return data
        }
        guard let data = data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func setExtendedAttribute(data: Data, forName name: String) throws {
        try self.withUnsafeFileSystemRepresentation { fileSystemPath in
            guard let fileSystemPath = fileSystemPath else { return }
            let result = data.withUnsafeBytes {
                setxattr(fileSystemPath, name, $0.baseAddress, data.count, 0, 0)
            }
            if result < 0 { throw URL.posixError(errno) }
        }
    }

    func removeExtendedAttribute(forName name: String) throws {
        try self.withUnsafeFileSystemRepresentation { fileSystemPath in
            guard let fileSystemPath = fileSystemPath else { return }
            let result = removexattr(fileSystemPath, name, 0)
            if result < 0 { throw URL.posixError(errno) }
        }
    }

    func listExtendedAttributes() throws -> [String] {
        try self.withUnsafeFileSystemRepresentation { fileSystemPath -> [String] in
            guard let fileSystemPath = fileSystemPath else { return [] }
            let length = listxattr(fileSystemPath, nil, 0, 0)
            if length < 0 { throw URL.posixError(errno) }
            if length == 0 { return [] }

            var data = Data(count: length)
            let result = data.withUnsafeMutableBytes {
                listxattr(fileSystemPath, $0.baseAddress, length, 0)
            }
            if result < 0 { throw URL.posixError(errno) }

            // Split null-terminated strings
            let list = data.split(separator: 0).compactMap {
                String(data: Data($0), encoding: .utf8)
            }
            return list
        }
    }

    static func posixError(_ err: Int32) -> NSError {
        return NSError(domain: NSPOSIXErrorDomain, code: Int(err), userInfo: nil)
    }
}