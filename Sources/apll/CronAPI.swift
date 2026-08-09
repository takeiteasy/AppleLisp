import Foundation
import JavaScriptCore
import AppleLisp

// MARK: - Cron Parser

public enum CronError: Error {
    case invalidFormat(String)
    case invalidValue(String)
}

public struct CronField {
    let values: Set<Int>
    
    public func contains(_ value: Int) -> Bool {
        return values.contains(value)
    }
}

public struct CronExpression {
    let minute: CronField
    let hour: CronField
    let dayOfMonth: CronField
    let month: CronField
    let dayOfWeek: CronField
    
    public init(_ expression: String) throws {
        let parts = expression.split(separator: " ").filter { !$0.isEmpty }
        guard parts.count == 5 else {
            throw CronError.invalidFormat("Expected 5 fields, got \(parts.count)")
        }
        
        self.minute = try CronExpression.parseField(String(parts[0]), min: 0, max: 59)
        self.hour = try CronExpression.parseField(String(parts[1]), min: 0, max: 23)
        self.dayOfMonth = try CronExpression.parseField(String(parts[2]), min: 1, max: 31)
        self.month = try CronExpression.parseField(String(parts[3]), min: 1, max: 12)
        // 0 and 7 are Sunday
        self.dayOfWeek = try CronExpression.parseField(String(parts[4]), min: 0, max: 7)
    }
    
    public func isDue(at date: Date) -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute, .hour, .day, .month, .weekday], from: date)
        
        guard let minute = components.minute,
              let hour = components.hour,
              let day = components.day,
              let month = components.month,
              let weekday = components.weekday else {
            return false
        }
        
        // Calendar.weekday returns 1 for Sunday, 7 for Saturday.
        // Cron usually expects 0-6 or 1-7 where 0/7 is Sunday.
        // Let's map Calendar weekday to Cron style (0=Sunday, ..., 6=Saturday)
        // Calendar: 1=Sun, 2=Mon, ..., 7=Sat
        // Cron: 0=Sun, 1=Mon, ..., 6=Sat
        let cronWeekday = weekday - 1
        
        // Handle 7 as Sunday in cron field
        let matchesWeekday = self.dayOfWeek.contains(cronWeekday) || (cronWeekday == 0 && self.dayOfWeek.contains(7))
        
        return self.minute.contains(minute) &&
               self.hour.contains(hour) &&
               self.dayOfMonth.contains(day) &&
               self.month.contains(month) &&
               matchesWeekday
    }
    
    private static func parseField(_ field: String, min: Int, max: Int) throws -> CronField {
        var values = Set<Int>()
        let parts = field.split(separator: ",")
        
        for part in parts {
            if part == "*" {
                for i in min...max { values.insert(i) }
            } else if part.contains("/") {
                let stepParts = part.split(separator: "/")
                guard stepParts.count == 2, let step = Int(stepParts[1]) else {
                    throw CronError.invalidFormat("Invalid step format: \(part)")
                }
                
                let rangePart = String(stepParts[0])
                var rangeStart = min
                var rangeEnd = max
                
                if rangePart != "*" {
                    if rangePart.contains("-") {
                        let rangeBounds = rangePart.split(separator: "-")
                        guard rangeBounds.count == 2,
                              let rStart = Int(rangeBounds[0]),
                              let rEnd = Int(rangeBounds[1]) else {
                            throw CronError.invalidFormat("Invalid range in step: \(rangePart)")
                        }
                        rangeStart = rStart
                        rangeEnd = rEnd
                    } else {
                        guard let start = Int(rangePart) else {
                             throw CronError.invalidFormat("Invalid start in step: \(rangePart)")
                        }
                        rangeStart = start
                        // If it's a single number with a step (e.g. 5/10), it usually means start at 5, step 10 until max
                    }
                }
                
                for i in stride(from: rangeStart, through: rangeEnd, by: step) {
                    if i >= min && i <= max {
                        values.insert(i)
                    }
                }
                
            } else if part.contains("-") {
                let rangeParts = part.split(separator: "-")
                guard rangeParts.count == 2,
                      let start = Int(rangeParts[0]),
                      let end = Int(rangeParts[1]) else {
                    throw CronError.invalidFormat("Invalid range format: \(part)")
                }
                for i in start...end {
                    if i >= min && i <= max {
                        values.insert(i)
                    }
                }
            } else {
                guard let value = Int(part) else {
                    throw CronError.invalidValue("Invalid integer value: \(part)")
                }
                if value >= min && value <= max {
                    values.insert(value)
                }
            }
        }
        
        return CronField(values: values)
    }
}

// MARK: - Cron Job & Scheduler

class CronJob {
    let id: String
    let expression: CronExpression
    let expressionString: String
    let callback: JSValue
    var lastRun: Date?
    
    init(id: String, expression: CronExpression, expressionString: String, callback: JSValue) {
        self.id = id
        self.expression = expression
        self.expressionString = expressionString
        self.callback = callback
    }
}

public class CronScheduler {
    private var jobs: [String: CronJob] = [:]
    private var timer: Timer?
    private let queue = DispatchQueue(label: "com.mmacs.cron")
    
    public init() {}
    
    public func start() {
        // Schedule timer to run every minute
        // We align it to the start of the next minute
        scheduleNextTick()
    }
    
    private func scheduleNextTick() {
        let now = Date()
        let calendar = Calendar.current
        
        // Calculate interval to next minute
        guard let nextMinute = calendar.date(byAdding: .minute, value: 1, to: now) else { return }
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: nextMinute)
        // Zero out seconds to fire exactly at :00
        var alignedComponents = components
        alignedComponents.second = 0
        guard let fireDate = calendar.date(from: alignedComponents) else { return }
        
        let interval = fireDate.timeIntervalSince(now)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) { [weak self] in
            self?.tick()
            self?.scheduleNextTick()
        }
    }
    
    private func tick() {
        let now = Date()
        // We might be slightly off, but Cron resolution is 1 minute.
        // We should check if the job matches the current minute.
        
        // To avoid double execution if tick is slightly delayed/jittery,
        // we could track last execution minute, but for now simple check is fine.
        
        let currentJobs = Array(jobs.values)
        for job in currentJobs {
            if job.expression.isDue(at: now) {
                // Ensure we don't run twice in the same minute (though tick only happens once per min)
                if let lastRun = job.lastRun {
                   let calendar = Calendar.current
                   if calendar.isDate(lastRun, equalTo: now, toGranularity: .minute) {
                       continue
                   }
                }
                
                job.lastRun = now
                job.callback.call(withArguments: [])
            }
        }
    }
    
    public func schedule(expression: String, callback: JSValue) throws -> String {
        let cronExpr = try CronExpression(expression)
        let id = UUID().uuidString
        let job = CronJob(id: id, expression: cronExpr, expressionString: expression, callback: callback)
        jobs[id] = job
        return id
    }
    
    public func unschedule(id: String) {
        jobs.removeValue(forKey: id)
    }
    
    public func listJobs() -> [[String: Any]] {
        return jobs.values.map { job in
            return [
                "id": job.id,
                "expression": job.expressionString,
                "lastRun": job.lastRun?.description ?? "never"
            ]
        }
    }
    
    public func stop() {
        // Since we use asyncAfter recursion, we can just flag stopped or clear jobs.
        // For now, no explicit stop needed unless we want to pause the scheduler.
    }
}

// MARK: - Cron API

public struct CronAPI: NativeAPIProvider {
    public static var apiName: String { "Cron" }
    
    private static var scheduler = CronScheduler()
    private static var isStarted = false
    
    public static func install(in context: JSContext) -> JSValue {
        let api = JSValue(newObjectIn: context)!
        
        // Start scheduler if not started
        if !isStarted {
            scheduler.start()
            isStarted = true
        }
        
        // schedule(expression, callback) -> String | null
        let schedule: @convention(block) (String, JSValue) -> String? = { expression, callback in
            do {
                return try scheduler.schedule(expression: expression, callback: callback)
            } catch {
                print("Cron schedule error: \(error)")
                return nil
            }
        }
        api.setObject(unsafeBitCast(schedule, to: AnyObject.self),
                      forKeyedSubscript: "schedule" as NSString)
        
        // unschedule(id) -> Void
        let unschedule: @convention(block) (String) -> Void = { id in
            scheduler.unschedule(id: id)
        }
        api.setObject(unsafeBitCast(unschedule, to: AnyObject.self),
                      forKeyedSubscript: "unschedule" as NSString)
        
        // list() -> Array
        let list: @convention(block) () -> [[String: Any]] = {
            return scheduler.listJobs()
        }
        api.setObject(unsafeBitCast(list, to: AnyObject.self),
                      forKeyedSubscript: "list" as NSString)
        
        return api
    }
}
