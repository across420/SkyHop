import AVFoundation
import Foundation

// MARK: - Persistent scores & settings

enum ScoreStore {
    private static let bestKey = "skyhop.bestScore"
    private static let gamesKey = "skyhop.gamesPlayed"
    private static let mutedKey = "skyhop.muted"

    static var best: Int {
        get { UserDefaults.standard.integer(forKey: bestKey) }
        set { UserDefaults.standard.set(newValue, forKey: bestKey) }
    }

    static var gamesPlayed: Int {
        get { UserDefaults.standard.integer(forKey: gamesKey) }
        set { UserDefaults.standard.set(newValue, forKey: gamesKey) }
    }

    static var isMuted: Bool {
        get { UserDefaults.standard.bool(forKey: mutedKey) }
        set { UserDefaults.standard.set(newValue, forKey: mutedKey) }
    }
}

// MARK: - Sound effects

/// Plays short sound effects. Uses the "ambient" audio session so the game
/// respects the silent switch and never stops the player's own music or podcast.
final class AudioManager {
    static let shared = AudioManager()

    enum Sound: String, CaseIterable {
        case flap, score, hit, fall, button
    }

    private var pools: [Sound: [AVAudioPlayer]] = [:]
    private var nextIndex: [Sound: Int] = [:]
    private(set) var isMuted: Bool = ScoreStore.isMuted

    private init() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [])
        try? session.setActive(true)

        for sound in Sound.allCases {
            guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") else { continue }
            let voices = sound == .flap ? 4 : 2
            let players: [AVAudioPlayer] = (0..<voices).compactMap { _ in
                guard let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
                player.prepareToPlay()
                return player
            }
            pools[sound] = players
        }
    }

    func setMuted(_ muted: Bool) {
        isMuted = muted
        ScoreStore.isMuted = muted
    }

    func play(_ sound: Sound, volume: Float = 1) {
        guard !isMuted, let pool = pools[sound], !pool.isEmpty else { return }
        let index = (nextIndex[sound] ?? 0) % pool.count
        nextIndex[sound] = index + 1
        let player = pool[index]
        player.volume = volume
        player.currentTime = 0
        player.play()
    }
}
