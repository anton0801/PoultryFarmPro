import Foundation
import Combine
import Supabase


protocol ValidationService {
    func validate() async throws -> Bool
}

final class SupabaseValidationService: ValidationService {
    private let client: SupabaseClient
    
    init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: "https://wfprnlccckgkayhypele.supabase.co")!,
            supabaseKey: "sb_publishable_LtcGhMiJl5Lweu7LuZus_Q_C8of2BwJ"
        )
    }
    
    func validate() async throws -> Bool {
        do {
            let response: [ValidationRow] = try await client
                .from("validation")
                .select()
                .limit(1)
                .execute()
                .value
            
            guard let firstRow = response.first else {
                return false
            }
            
            return firstRow.isValid
        } catch {
            print("🐔 [PoultryFarm] Validation error: \(error)")
            throw error
        }
    }
}

struct ValidationRow: Codable {
    let id: Int?
    let isValid: Bool
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case isValid = "is_valid"
        case createdAt = "created_at"
    }
}
