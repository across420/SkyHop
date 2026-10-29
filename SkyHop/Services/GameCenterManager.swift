import GameKit
import UIKit

/// Signs the player in to Game Center, submits scores and shows the leaderboard.
/// Everything fails quietly if the player isn't signed in.
@MainActor
final class GameCenterManager: NSObject, GKGameCenterControllerDelegate {
    static let shared = GameCenterManager()

    private weak var presenter: UIViewController?
    private var didStartAuthentication = false

    var isAuthenticated: Bool { GKLocalPlayer.local.isAuthenticated }

    func authenticate(presenter: UIViewController) {
        self.presenter = presenter
        guard !didStartAuthentication else { return }
        didStartAuthentication = true

        GKLocalPlayer.local.authenticateHandler = { viewController, _ in
            guard let viewController else { return }
            Task { @MainActor in
                GameCenterManager.shared.present(viewController)
            }
        }
    }

    func submit(score: Int) {
        guard isAuthenticated, score > 0 else { return }
        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local,
                                  leaderboardIDs: [GameConfig.leaderboardID]) { _ in }
    }

    func showLeaderboard() {
        guard isAuthenticated else {
            let alert = UIAlertController(
                title: "Game Center",
                message: "Sign in to Game Center in the Settings app to compare scores with friends.",
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert)
            return
        }
        let controller = GKGameCenterViewController(leaderboardID: GameConfig.leaderboardID,
                                                    playerScope: .global,
                                                    timeScope: .allTime)
        controller.gameCenterDelegate = self
        present(controller)
    }

    nonisolated func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        Task { @MainActor in
            gameCenterViewController.dismiss(animated: true)
        }
    }

    private func present(_ controller: UIViewController) {
        guard let presenter, presenter.presentedViewController == nil else { return }
        presenter.present(controller, animated: true)
    }
}
