import CoreGraphics

/// All tuning numbers in one place. The world is always 800 units tall;
/// its width follows the device's aspect ratio.
enum GameConfig {
    // World
    static let worldHeight: CGFloat = 800
    static let groundHeight: CGFloat = 112

    // Hero physics (units per second)
    static let gravity: CGFloat = -1850
    static let flapVelocity: CGFloat = 540
    static let maxFallSpeed: CGFloat = -820
    static let heroHitRadius: CGFloat = 17      // slightly smaller than the art, feels fair
    static let heroSize = CGSize(width: 60, height: 54)
    static let heroXFraction: CGFloat = 0.3

    // Towers
    static let towerBodyWidth: CGFloat = 78
    static let towerCapWidth: CGFloat = 94
    static let towerCapHeight: CGFloat = 30
    static let towerSpacing: CGFloat = 245
    static let maxGapShift: CGFloat = 230       // max vertical jump between consecutive gaps

    // Difficulty ramps gently with score
    static func gap(for score: Int) -> CGFloat {
        max(158, 196 - CGFloat(score) * 0.9)
    }

    static func speed(for score: Int) -> CGFloat {
        min(215, 165 + CGFloat(score) * 1.2)
    }

    // Medals
    static let bronzeScore = 10
    static let silverScore = 25
    static let goldScore = 50
    static let platinumScore = 100

    // Game Center — create a leaderboard with this exact ID in App Store Connect.
    static let leaderboardID = "skyhop.highscore"
}
