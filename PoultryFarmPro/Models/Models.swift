import Foundation
import SwiftUI

// MARK: - User Model
struct UserProfile: Codable {
    var id: UUID = UUID()
    var name: String
    var email: String
    var farmName: String
    var createdAt: Date = Date()
}

// MARK: - Bird Group
struct BirdGroup: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var birdType: BirdType
    var count: Int
    var ageWeeks: Int
    var coopId: UUID?
    var notes: String = ""
    var createdAt: Date = Date()

    var ageDescription: String {
        if ageWeeks < 8 { return "Chick" }
        if ageWeeks < 20 { return "Pullet/Juvenile" }
        return "Adult"
    }
}

enum BirdType: String, Codable, CaseIterable {
    case chicken = "Chicken"
    case duck = "Duck"
    case goose = "Goose"
    case turkey = "Turkey"
    case quail = "Quail"
    case guinea = "Guinea Fowl"

    var icon: String {
        switch self {
        case .chicken: return "🐔"
        case .duck: return "🦆"
        case .goose: return "🪿"
        case .turkey: return "🦃"
        case .quail: return "🐦"
        case .guinea: return "🐓"
        }
    }

    var systemIcon: String {
        return "bird"
    }
}

// MARK: - Coop
struct Coop: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var capacity: Int
    var notes: String = ""
    var createdAt: Date = Date()

    var occupancy: Int = 0
    var occupancyPercent: Double {
        guard capacity > 0 else { return 0 }
        return min(Double(occupancy) / Double(capacity), 1.0)
    }
}

// MARK: - Egg Record
struct EggRecord: Identifiable, Codable {
    var id: UUID = UUID()
    var birdGroupId: UUID?
    var birdGroupName: String
    var count: Int
    var date: Date
    var notes: String = ""
}

// MARK: - Feed Record
struct FeedRecord: Identifiable, Codable {
    var id: UUID = UUID()
    var feedType: FeedType
    var amountKg: Double
    var birdGroupId: UUID?
    var birdGroupName: String = "All Birds"
    var date: Date
    var notes: String = ""
}

enum FeedType: String, Codable, CaseIterable {
    case corn = "Corn"
    case wheat = "Wheat"
    case feedMix = "Feed Mix"
    case barley = "Barley"
    case soybeans = "Soybeans"
    case pellets = "Layer Pellets"
    case scratch = "Scratch Grains"

    var color: Color {
        switch self {
        case .corn: return Color(hex: "#F9C74F")
        case .wheat: return Color(hex: "#C09A6B")
        case .feedMix: return Color(hex: "#52B788")
        case .barley: return Color(hex: "#7C5C3A")
        case .soybeans: return Color(hex: "#A0C878")
        case .pellets: return Color(hex: "#4CC9F0")
        case .scratch: return Color(hex: "#F4A261")
        }
    }
}

// MARK: - Storage Item
struct StorageItem: Identifiable, Codable {
    var id: UUID = UUID()
    var feedType: FeedType
    var quantityKg: Double
    var reorderLevelKg: Double
    var lastUpdated: Date = Date()

    var isLow: Bool { quantityKg <= reorderLevelKg }
}

// MARK: - Breeding Pair
struct BreedingPair: Identifiable, Codable {
    var id: UUID = UUID()
    var maleGroupId: UUID?
    var femaleGroupId: UUID?
    var maleName: String
    var femaleName: String
    var startDate: Date
    var expectedHatchDate: Date?
    var status: BreedingStatus
    var notes: String = ""
}

enum BreedingStatus: String, Codable, CaseIterable {
    case active = "Active"
    case incubating = "Incubating"
    case hatched = "Hatched"
    case paused = "Paused"
    case completed = "Completed"

    var color: Color {
        switch self {
        case .active: return .farmGreen
        case .incubating: return .hayAmber
        case .hatched: return .infoBlue
        case .paused: return .textMuted
        case .completed: return .soilBrown
        }
    }
}

// MARK: - Incubator Batch
struct IncubatorBatch: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var eggCount: Int
    var startDate: Date
    var birdType: BirdType
    var notes: String = ""
    var temperature: Double = 37.5
    var humidity: Double = 55.0
    var turnedToday: Bool = false

    var incubationDays: Int {
        switch birdType {
        case .chicken: return 21
        case .duck: return 28
        case .goose: return 30
        case .turkey: return 28
        case .quail: return 17
        case .guinea: return 26
        }
    }

    var expectedHatchDate: Date {
        Calendar.current.date(byAdding: .day, value: incubationDays, to: startDate) ?? startDate
    }

    var daysRemaining: Int {
        let remaining = Calendar.current.dateComponents([.day], from: Date(), to: expectedHatchDate).day ?? 0
        return max(0, remaining)
    }

    var progress: Double {
        let total = Double(incubationDays)
        let elapsed = Double(Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0)
        return min(elapsed / total, 1.0)
    }
}

// MARK: - Health Record
struct HealthRecord: Identifiable, Codable {
    var id: UUID = UUID()
    var birdGroupId: UUID?
    var birdGroupName: String
    var issue: String
    var severity: HealthSeverity
    var treatment: String = ""
    var date: Date
    var resolved: Bool = false
    var resolvedDate: Date?
}

enum HealthSeverity: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"

    var color: Color {
        switch self {
        case .low: return .farmGreen
        case .medium: return .warningYellow
        case .high: return .hayAmberDeep
        case .critical: return .alertRed
        }
    }
}

// MARK: - Task
struct FarmTask: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var category: TaskCategory
    var dueDate: Date
    var completed: Bool = false
    var notes: String = ""
    var recurring: TaskRecurrence = .none
}

enum TaskCategory: String, Codable, CaseIterable {
    case feeding = "Feeding"
    case cleaning = "Cleaning"
    case health = "Health"
    case breeding = "Breeding"
    case harvest = "Harvest"
    case maintenance = "Maintenance"
    case other = "Other"

    var icon: String {
        switch self {
        case .feeding: return "fork.knife"
        case .cleaning: return "sparkles"
        case .health: return "cross.fill"
        case .breeding: return "heart.fill"
        case .harvest: return "leaf.fill"
        case .maintenance: return "wrench.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .feeding: return .hayAmber
        case .cleaning: return .infoBlue
        case .health: return .alertRed
        case .breeding: return Color(hex: "#FF6B9D")
        case .harvest: return .farmGreen
        case .maintenance: return .soilBrown
        case .other: return .textSecondary
        }
    }
}

enum TaskRecurrence: String, Codable, CaseIterable {
    case none = "None"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
}

// MARK: - Feed Crop
struct FeedCrop: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var cropType: CropType
    var plantedDate: Date?
    var expectedHarvestDate: Date?
    var areaSquareMeters: Double
    var status: CropStatus
    var estimatedYieldKg: Double
    var actualYieldKg: Double?
    var notes: String = ""
}

enum CropType: String, Codable, CaseIterable {
    case corn = "Corn"
    case wheat = "Wheat"
    case barley = "Barley"
    case sunflower = "Sunflower"
    case soybeans = "Soybeans"
    case oats = "Oats"

    var icon: String {
        switch self {
        case .corn: return "🌽"
        case .wheat: return "🌾"
        case .barley: return "🌾"
        case .sunflower: return "🌻"
        case .soybeans: return "🫘"
        case .oats: return "🌾"
        }
    }
}

enum CropStatus: String, Codable, CaseIterable {
    case planned = "Planned"
    case planted = "Planted"
    case growing = "Growing"
    case readyToHarvest = "Ready to Harvest"
    case harvested = "Harvested"

    var color: Color {
        switch self {
        case .planned: return .textMuted
        case .planted: return .infoBlue
        case .growing: return .farmGreenLight
        case .readyToHarvest: return .hayAmber
        case .harvested: return .farmGreen
        }
    }
}

// MARK: - Cost Record
struct CostRecord: Identifiable, Codable {
    var id: UUID = UUID()
    var category: CostCategory
    var amount: Double
    var description: String
    var date: Date
}

enum CostCategory: String, Codable, CaseIterable {
    case feed = "Feed"
    case medicine = "Medicine"
    case equipment = "Equipment"
    case labor = "Labor"
    case utilities = "Utilities"
    case other = "Other"

    var icon: String {
        switch self {
        case .feed: return "bag.fill"
        case .medicine: return "cross.vial.fill"
        case .equipment: return "wrench.and.screwdriver.fill"
        case .labor: return "person.fill"
        case .utilities: return "bolt.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .feed: return .hayAmber
        case .medicine: return .alertRed
        case .equipment: return .soilBrown
        case .labor: return .infoBlue
        case .utilities: return .warningYellow
        case .other: return .textSecondary
        }
    }
}

// MARK: - Activity
struct ActivityItem: Identifiable, Codable {
    var id: UUID = UUID()
    var type: ActivityType
    var description: String
    var date: Date = Date()
}

enum ActivityType: String, Codable {
    case eggCollected = "egg"
    case birdAdded = "bird"
    case feedRecorded = "feed"
    case healthRecorded = "health"
    case incubatorUpdated = "incubator"
    case taskCompleted = "task"
    case cropUpdated = "crop"
    case costAdded = "cost"

    var icon: String {
        switch self {
        case .eggCollected: return "oval.fill"
        case .birdAdded: return "bird.fill"
        case .feedRecorded: return "bag.fill"
        case .healthRecorded: return "cross.fill"
        case .incubatorUpdated: return "thermometer.medium"
        case .taskCompleted: return "checkmark.circle.fill"
        case .cropUpdated: return "leaf.fill"
        case .costAdded: return "dollarsign.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .eggCollected: return .eggYolk
        case .birdAdded: return .farmGreen
        case .feedRecorded: return .hayAmber
        case .healthRecorded: return .alertRed
        case .incubatorUpdated: return .infoBlue
        case .taskCompleted: return .healthGreen
        case .cropUpdated: return .farmGreenLight
        case .costAdded: return .soilBrown
        }
    }
}
