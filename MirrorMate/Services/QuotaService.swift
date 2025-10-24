import Foundation
import Supabase

@MainActor
final class QuotaService {
    static let shared = QuotaService()
    private init() {}
    
    private let client = SupabaseService.shared.client
    private let dailyFreeLimit = 1 // Free users get 1 analysis per day
    
    // MARK: - Check Quota
    
    func canAnalyzeToday(isPremium: Bool) async -> Bool {
        if isPremium {
            AppLog.info("Premium user - unlimited quota", category: .general)
            return true
        }
        
        // For authenticated users, check database
        if let userId = AuthService.shared.userId {
            return await checkUserQuota(userId: userId)
        }
        
        // Fallback to device-based quota (for anonymous users)
        return checkLocalQuota()
    }
    
    private func checkUserQuota(userId: UUID) async -> Bool {
        do {
            AppLog.info("Checking quota for user: \(userId)", category: .general)
            
            let today = Self.todayString()
            
            // Fetch user's quota record
            let response: [UserQuotaRecord] = try await client
                .from("user_quotas")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            
            if let quota = response.first {
                // Check if last analysis was today
                if quota.last_analysis_date == today {
                    let canAnalyze = quota.daily_count < dailyFreeLimit
                    AppLog.info("Quota check: used \(quota.daily_count)/\(dailyFreeLimit) today", category: .general)
                    return canAnalyze
                } else {
                    // New day - reset available
                    AppLog.info("New day - quota reset", category: .general)
                    return true
                }
            } else {
                // No quota record - first time user
                AppLog.info("New user - quota available", category: .general)
                return true
            }
        } catch {
            AppLog.error("Error checking quota: \(error)", category: .general)
            // On error, allow (fail open)
            return true
        }
    }
    
    private func checkLocalQuota() -> Bool {
        let key = "mm_free_quota_last_date"
        let today = Self.todayString()
        let last = UserDefaults.standard.string(forKey: key)
        let canAnalyze = last != today
        AppLog.info("Local quota check: \(canAnalyze ? "available" : "used")", category: .general)
        return canAnalyze
    }
    
    // MARK: - Mark Used
    
    func markUsedToday() async {
        // For authenticated users, update database
        if let userId = AuthService.shared.userId {
            await markUserQuotaUsed(userId: userId)
        }
        
        // Also mark locally as backup
        markLocalQuotaUsed()
    }
    
    private func markUserQuotaUsed(userId: UUID) async {
        do {
            AppLog.info("Marking quota used for user: \(userId)", category: .general)
            
            let today = Self.todayString()
            let now = ISO8601DateFormatter().string(from: Date())
            
            // Try to fetch existing quota record
            let existing: [UserQuotaRecord] = try await client
                .from("user_quotas")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            
            if let quota = existing.first {
                // Update existing record
                struct QuotaUpdate: Encodable {
                    let daily_count: Int?
                    let last_analysis_date: String?
                    let updated_at: String
                }
                
                let update: QuotaUpdate
                if quota.last_analysis_date == today {
                    // Same day - increment count
                    update = QuotaUpdate(
                        daily_count: quota.daily_count + 1,
                        last_analysis_date: nil,
                        updated_at: now
                    )
                } else {
                    // New day - reset count
                    update = QuotaUpdate(
                        daily_count: 1,
                        last_analysis_date: today,
                        updated_at: now
                    )
                }
                
                try await client
                    .from("user_quotas")
                    .update(update)
                    .eq("id", value: quota.id.uuidString)
                    .execute()
                
                AppLog.info("✓ Quota updated in database", category: .general)
            } else {
                // Create new record
                struct QuotaInsert: Encodable {
                    let user_id: String
                    let last_analysis_date: String
                    let daily_count: Int
                }
                
                let insert = QuotaInsert(
                    user_id: userId.uuidString,
                    last_analysis_date: today,
                    daily_count: 1
                )
                
                try await client
                    .from("user_quotas")
                    .insert(insert)
                    .execute()
                
                AppLog.info("✓ Quota record created", category: .general)
            }
        } catch {
            AppLog.error("Error marking quota used: \(error)", category: .general)
        }
    }
    
    private func markLocalQuotaUsed() {
        let key = "mm_free_quota_last_date"
        UserDefaults.standard.set(Self.todayString(), forKey: key)
    }
    
    // MARK: - Helpers
    
    private static func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter.string(from: Date())
    }
}

// MARK: - Models

struct UserQuotaRecord: Codable {
    let id: UUID
    let user_id: UUID?
    let device_id: String?
    let last_analysis_date: String?
    let daily_count: Int
    let created_at: String
    let updated_at: String
}


