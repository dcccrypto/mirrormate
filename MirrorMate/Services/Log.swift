import Foundation
import os

enum LogLevel: String {
    case debug = "🔍 DEBUG"
    case info = "ℹ️  INFO"
    case warning = "⚠️  WARN"
    case error = "❌ ERROR"
    case critical = "🚨 CRITICAL"
}

enum LogCategory: String {
    case general = "General"
    case network = "Network"
    case upload = "Upload"
    case analysis = "Analysis"
    case ui = "UI"
    case capture = "Capture"
    case storage = "Storage"
}

enum AppLog {
    private static let dateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss.SSS"
        return fmt
    }()
    
    private static func log(_ level: LogLevel, _ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        let timestamp = dateFormatter.string(from: Date())
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(timestamp)] \(level.rawValue) [\(category.rawValue)] \(message)"
        
        // Console output with color-coded levels
        print(logMessage)
        
        // OS Logger for system integration
        if #available(iOS 14.0, *) {
            let logger = Logger(subsystem: "com.mirrormate.app", category: category.rawValue)
            switch level {
            case .debug:
                logger.debug("\(message, privacy: .public)")
            case .info:
                logger.info("\(message, privacy: .public)")
            case .warning:
                logger.warning("\(message, privacy: .public)")
            case .error:
                logger.error("\(message, privacy: .public)")
            case .critical:
                logger.critical("\(message, privacy: .public)")
            }
        }
    }
    
    static func debug(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        log(.debug, message, category: category, file: file, function: function, line: line)
        #endif
    }
    
    static func info(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(.info, message, category: category, file: file, function: function, line: line)
    }
    
    static func warning(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(.warning, message, category: category, file: file, function: function, line: line)
    }
    
    static func error(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(.error, message, category: category, file: file, function: function, line: line)
    }
    
    static func critical(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(.critical, message, category: category, file: file, function: function, line: line)
    }
    
    // Specialized logging for network requests
    static func logRequest(_ request: URLRequest, category: LogCategory = .network) {
        var logMessage = "→ \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "unknown")"
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            logMessage += "\n  Headers: \(headers.map { "\($0.key): \($0.value)" }.joined(separator: ", "))"
        }
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            logMessage += "\n  Body: \(bodyString)"
        }
        info(logMessage, category: category)
    }
    
    static func logResponse(_ response: URLResponse?, data: Data?, error: Error?, category: LogCategory = .network) {
        if let error = error {
            AppLog.error("← Response error: \(error.localizedDescription)", category: category)
            return
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            let statusEmoji = (200..<300).contains(httpResponse.statusCode) ? "✅" : "❌"
            var logMessage = "← \(statusEmoji) \(httpResponse.statusCode) \(httpResponse.url?.absoluteString ?? "")"
            
            if let data = data, let bodyString = String(data: data, encoding: .utf8) {
                let preview = bodyString.prefix(200)
                logMessage += "\n  Response: \(preview)\(bodyString.count > 200 ? "..." : "")"
            }
            
            let level: LogLevel = (200..<300).contains(httpResponse.statusCode) ? .info : .error
            log(level, logMessage, category: category)
        }
    }
    
    // Progress tracking
    static func logProgress(_ progress: Double, task: String, category: LogCategory = .general) {
        let percentage = Int(progress * 100)
        let bars = Int(progress * 20)
        let progressBar = String(repeating: "█", count: bars) + String(repeating: "░", count: 20 - bars)
        info("[\(progressBar)] \(percentage)% - \(task)", category: category)
    }
}


