import SpriteKit
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        _ = AudioManager.shared   // set up the audio session and preload sounds
        return true
    }

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Default", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
}

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        let gameController = GameViewController()
        window.rootViewController = gameController
        window.makeKeyAndVisible()
        self.window = window

        GameCenterManager.shared.authenticate(presenter: gameController)
    }

    func sceneWillResignActive(_ scene: UIScene) {
        (window?.rootViewController as? GameViewController)?.pauseGame()
    }
}

final class GameViewController: UIViewController {
    private var gameScene: GameScene?

    private var skView: SKView {
        // swiftlint:disable:next force_cast
        view as! SKView
    }

    override func loadView() {
        view = SKView(frame: .zero)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        skView.ignoresSiblingOrder = false
        skView.isMultipleTouchEnabled = false
        skView.preferredFramesPerSecond = 120   // capped to what the display supports
        skView.backgroundColor = Palette.skyBottom
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        presentSceneIfNeeded()
        updateSafeArea()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateSafeArea()
    }

    /// The world is always 800 units tall; width follows the screen's aspect ratio,
    /// so every iPhone shows the full play area with nothing cropped.
    private func presentSceneIfNeeded() {
        let bounds = view.bounds.size
        guard gameScene == nil, bounds.width > 0, bounds.height > 0 else { return }
        let height = GameConfig.worldHeight
        let width = height * bounds.width / bounds.height
        let scene = GameScene(size: CGSize(width: width, height: height))
        scene.scaleMode = .aspectFit
        skView.presentScene(scene)
        gameScene = scene
    }

    private func updateSafeArea() {
        guard let gameScene, view.bounds.height > 0 else { return }
        gameScene.safeTopInset = view.safeAreaInsets.top * GameConfig.worldHeight / view.bounds.height
    }

    func pauseGame() {
        gameScene?.pauseIfPlaying()
    }

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { .bottom }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
}
