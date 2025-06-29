
import Foundation
import Combine

enum WeightUnit: String, CaseIterable {
    case kg = "KG"
    case lbs = "LBS"
}

enum DistanceUnit: String, CaseIterable {
    case km = "KM"
    case miles = "MILES"
}

enum AppTheme: String, CaseIterable {
    case neutral = "NEUTRAL"
    case light = "LIGHT"
    case dark = "DARK"
}

class UserPreferences: ObservableObject {
    private let userDefaults = UserDefaults.standard
    private let logger = "UserPreferences"
    
    // MARK: - Keys
    private enum Keys {
        static let isSignedIn = "is_user_signed_in"
        static let appTheme = "app_theme"
        static let weightUnit = "weight_unit"
        static let distanceUnit = "distance_unit"
    }
    
    // MARK: - Published Properties
    @Published var isUserSignedIn: Bool {
        didSet {
            userDefaults.set(isUserSignedIn, forKey: Keys.isSignedIn)
            print("\(logger): Setting user signed in to: \(isUserSignedIn)")
        }
    }
    
    @Published var weightUnit: WeightUnit {
        didSet {
            userDefaults.set(weightUnit.rawValue, forKey: Keys.weightUnit)
            print("\(logger): Setting weight unit to: \(weightUnit.rawValue)")
        }
    }
    
    @Published var distanceUnit: DistanceUnit {
        didSet {
            userDefaults.set(distanceUnit.rawValue, forKey: Keys.distanceUnit)
            print("\(logger): Setting distance unit to: \(distanceUnit.rawValue)")
        }
    }
    
    @Published var appTheme: AppTheme {
        didSet {
            userDefaults.set(appTheme.rawValue, forKey: Keys.appTheme)
            print("\(logger): Setting app theme to: \(appTheme.rawValue)")
        }
    }
    
    // MARK: - Initialization
    init() {
        self.isUserSignedIn = userDefaults.bool(forKey: Keys.isSignedIn)
        
        let weightUnitString = userDefaults.string(forKey: Keys.weightUnit) ?? WeightUnit.kg.rawValue
        self.weightUnit = WeightUnit(rawValue: weightUnitString) ?? .kg
        
        let distanceUnitString = userDefaults.string(forKey: Keys.distanceUnit) ?? DistanceUnit.km.rawValue
        self.distanceUnit = DistanceUnit(rawValue: distanceUnitString) ?? .km
        
        let themeString = userDefaults.string(forKey: Keys.appTheme) ?? AppTheme.neutral.rawValue
        self.appTheme = AppTheme(rawValue: themeString) ?? .neutral
    }
    
    // MARK: - Methods
    func setUserSignedIn(_ isSignedIn: Bool) {
        print("\(logger): Setting user signed in to: \(isSignedIn)")
        self.isUserSignedIn = isSignedIn
    }
    
    func setAppTheme(_ theme: AppTheme) {
        print("\(logger): Setting app theme to: \(theme.rawValue)")
        self.appTheme = theme
    }
    
    func setWeightUnit(_ unit: WeightUnit) {
        print("\(logger): Setting weight unit to: \(unit.rawValue)")
        self.weightUnit = unit
    }
    
    func setDistanceUnit(_ unit: DistanceUnit) {
        print("\(logger): Setting distance unit to: \(unit.rawValue)")
        self.distanceUnit = unit
    }
    
    func clearPreferences() {
        print("\(logger): Clearing all preferences")
        do {
            userDefaults.removeObject(forKey: Keys.isSignedIn)
            userDefaults.removeObject(forKey: Keys.appTheme)
            userDefaults.removeObject(forKey: Keys.weightUnit)
            userDefaults.removeObject(forKey: Keys.distanceUnit)
            
            // Reset to defaults
            self.isUserSignedIn = false
            self.weightUnit = .kg
            self.distanceUnit = .km
            self.appTheme = .neutral
            
            print("\(logger): Preferences cleared successfully")
        } catch {
            print("\(logger): Error clearing preferences: \(error)")
        }
    }
}
