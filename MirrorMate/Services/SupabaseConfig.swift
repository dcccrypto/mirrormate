import Foundation

struct SupabaseConfig {
    // TODO: Replace with your Supabase project URL and anon key
    // Get these from https://supabase.com/dashboard/project/YOUR_PROJECT/settings/api
    static let url = "https://lchudacxfedkylmjbdsz.supabase.co"
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxjaHVkYWN4ZmVka3lsbWpiZHN6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1Njk2MjMsImV4cCI6MjA3NjE0NTYyM30.DzhVuivavXFu0341l7LJUt5BPLYbFEKr38wAXz_xHl8"
    static let serviceRoleKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxjaHVkYWN4ZmVka3lsbWpiZHN6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MDU2OTYyMywiZXhwIjoyMDc2MTQ1NjIzfQ.hnKDtPGHJhUwhOc0KGVIzyovugk-SpRPHkRtxsHrTUI"
    
    
    // For testing locally with Supabase CLI:
    // static let url = "http://localhost:54321"
    // static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
