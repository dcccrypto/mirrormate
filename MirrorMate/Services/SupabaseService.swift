import Foundation
import Supabase

final class SupabaseService {
    static let shared = SupabaseService()
    let client: SupabaseClient

    private init() {
        let url = URL(string: SupabaseConfig.url)!
        client = SupabaseClient(supabaseURL: url, supabaseKey: SupabaseConfig.anonKey)
    }
}


