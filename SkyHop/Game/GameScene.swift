import SpriteKit
import StoreKit
import UIKit

private final class Tower {
    let node: SKNode
    let gapCenter: CGFloat
    let gap: CGFloat
    var scored = false

    init(node: SKNode, gapCenter: CGFloat, gap: CGFloat) {
        self.node = node
        self.gapCenter = gapCenter
        self.gap = gap
    }
}

final class GameScene: SKScene {

    enum State { case menu, ready, playing, paused, dying, gameOver }

    /// Height of the notch / Dynamic Island area, in scene units.
    var safeTopInset: CGFloat = 0 {
        didSet { layoutHUD() }
    }

    // MARK: Nodes

    private let world = SKNode()
    private let hero = SKSpriteNode(texture: Textures.heroFrames[0], size: GameConfig.heroSize)
    private let scoreLabel = OutlinedLabel(text: "0", fontSize: 60, color: .white, outline: Palette.ink,
                                           outlineWidth: 4, shadowOffset: 4)
    private var groundTiles: [SKSpriteNode] = []
    private var nearHillTiles: [SKSpriteNode] = []
    private var farHillTiles: [SKSpriteNode] = []
    private var clouds: [SKSpriteNode] = []
    private var towers: [Tower] = []
    private var overlay: SKNode?

    // MARK: State

    private(set) var state: State = .menu
    private var heroVelocity: CGFloat = 0
    private var score = 0
    private var lastUpdate: TimeInterval = 0
    private var distanceSinceSpawn: CGFloat = 0
    private var lastGapCenter: CGFloat?
    private var pressedButton: ButtonNode?
    private var isSetUp = false

    private let flapHaptic = UIImpactFeedbackGenerator(style: .light)
    private let scoreHaptic = UISelectionFeedbackGenerator()
    private let hitHaptic = UIImpactFeedbackGenerator(style: .heavy)

    private var heroStart: CGPoint { CGPoint(x: size.width * GameConfig.heroXFraction, y: size.height * 0.56) }

    // MARK: - Setup

    override func didMove(to view: SKView) {
        guard !isSetUp else { return }
        isSetUp = true
        backgroundColor = Palette.skyBottom
        addChild(world)

        buildSky()
        buildClouds()
        buildHills()
        buildGround()
        buildHero()

        scoreLabel.zPosition = 100
        addChild(scoreLabel)
        layoutHUD()

        showMenu()
    }

    private func buildSky() {
        let sky = SKSpriteNode(texture: Textures.sky)
        sky.anchorPoint = .zero
        sky.size = CGSize(width: size.width + 40, height: size.height + 40)
        sky.position = CGPoint(x: -20, y: -20)
        sky.zPosition = -100
        world.addChild(sky)
    }

    private func buildClouds() {
        for i in 0..<5 {
            let cloud = SKSpriteNode(texture: Textures.cloud, size: Textures.cloudSize)
            cloud.setScale(CGFloat.random(in: 0.55...1.1))
            cloud.alpha = 0.95
            cloud.zPosition = -90
            cloud.position = CGPoint(x: size.width * CGFloat(i) / 4 + CGFloat.random(in: -30...30),
                                     y: CGFloat.random(in: size.height * 0.5...size.height * 0.9))
            world.addChild(cloud)
            clouds.append(cloud)
        }
    }

    private func makeTiles(texture: SKTexture, tileSize: CGSize, y: CGFloat, z: CGFloat) -> [SKSpriteNode] {
        let count = Int(ceil(size.width / tileSize.width)) + 1
        return (0..<count).map { i in
            let tile = SKSpriteNode(texture: texture)
            tile.anchorPoint = .zero
            tile.size = CGSize(width: tileSize.width + 1, height: tileSize.height)   // +1 hides seams
            tile.position = CGPoint(x: CGFloat(i) * tileSize.width, y: y)
            tile.zPosition = z
            world.addChild(tile)
            return tile
        }
    }

    private func buildHills() {
        farHillTiles = makeTiles(texture: Textures.farHills, tileSize: CGSize(width: Textures.hillWidth, height: 180),
                                 y: GameConfig.groundHeight - 4, z: -80)
        nearHillTiles = makeTiles(texture: Textures.nearHills, tileSize: CGSize(width: Textures.hillWidth, height: 120),
                                  y: GameConfig.groundHeight - 4, z: -70)
    }

    private func buildGround() {
        groundTiles = makeTiles(texture: Textures.ground, tileSize: Textures.groundSize, y: 0, z: 10)
    }

    private func buildHero() {
        hero.zPosition = 20
        hero.position = heroStart
        world.addChild(hero)
        startWingAnimation()
    }

    private func layoutHUD() {
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height - safeTopInset - 70)
    }

    // MARK: - Hero animation

    private func startWingAnimation() {
        hero.removeAction(forKey: "wings")
        hero.run(.repeatForever(.animate(with: Textures.heroFrames, timePerFrame: 0.075)), withKey: "wings")
    }

    private func startHeroBob() {
        let up = SKAction.moveBy(x: 0, y: 8, duration: 0.45)
        up.timingMode = .easeInEaseOut
        let down = up.reversed()
        hero.run(.repeatForever(.sequence([up, down])), withKey: "bob")
    }

    // MARK: - Screens

    private func setOverlay(_ node: SKNode?) {
        if let old = overlay {
            old.run(.sequence([.fadeOut(withDuration: 0.15), .removeFromParent()]))
        }
        overlay = node
        guard let node else { return }
        node.zPosition = 200
        node.alpha = 0
        addChild(node)
        node.run(.fadeIn(withDuration: 0.2))
    }

    private func showMenu() {
        state = .menu
        scoreLabel.isHidden = true
        hero.position = CGPoint(x: size.width / 2, y: size.height * 0.56)
        hero.zRotation = 0
        startHeroBob()
        setOverlay(makeMenuOverlay())
    }

    private func startReady() {
        let comingFromMenu = state == .menu
        state = .ready

        clearTowers()
        score = 0
        scoreLabel.text = "0"
        scoreLabel.isHidden = false
        scoreLabel.alpha = 1
        heroVelocity = 0
        lastGapCenter = nil

        hero.removeAllActions()
        hero.zRotation = 0
        startWingAnimation()
        if comingFromMenu {
            let move = SKAction.move(to: heroStart, duration: 0.35)
            move.timingMode = .easeInEaseOut
            hero.run(.sequence([move, .onMain { [weak self] in self?.startHeroBob() }]), withKey: "move")
        } else {
            hero.position = heroStart
            startHeroBob()
        }

        setOverlay(makeReadyOverlay())
        flapHaptic.prepare()
    }

    private func startPlaying() {
        state = .playing
        hero.removeAction(forKey: "bob")
        hero.removeAction(forKey: "move")
        heroVelocity = 0
        distanceSinceSpawn = GameConfig.towerSpacing   // spawn the first tower right away (off-screen)
        setOverlay(nil)
    }

    func pauseIfPlaying() {
        guard state == .playing else { return }
        state = .paused
        setOverlay(makePausedOverlay())
    }

    private func resume() {
        state = .playing
        setOverlay(nil)
        flap()
    }

    // MARK: - Input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)

        if let button = button(at: point) {
            pressedButton = button
            button.setPressed(true)
            return
        }

        switch state {
        case .menu: startReady()
        case .ready: startPlaying(); flap()
        case .playing: flap()
        case .paused: resume()
        case .dying, .gameOver: break
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let button = pressedButton else { return }
        pressedButton = nil
        button.setPressed(false)
        guard let touch = touches.first, self.button(at: touch.location(in: self)) === button else { return }
        AudioManager.shared.play(.button, volume: 0.7)
        button.action(button)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        pressedButton?.setPressed(false)
        pressedButton = nil
    }

    private func button(at point: CGPoint) -> ButtonNode? {
        for node in nodes(at: point) {
            var current: SKNode? = node
            while let candidate = current {
                if let button = candidate as? ButtonNode {
                    return button.isEnabled ? button : nil
                }
                current = candidate.parent
            }
        }
        return nil
    }

    private func flap() {
        heroVelocity = GameConfig.flapVelocity
        AudioManager.shared.play(.flap, volume: 0.5)
        flapHaptic.impactOccurred(intensity: 0.5)
        flapHaptic.prepare()
    }

    // MARK: - Game loop

    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdate == 0 ? 0 : CGFloat(min(currentTime - lastUpdate, 1.0 / 30.0))
        lastUpdate = currentTime
        guard dt > 0 else { return }

        switch state {
        case .menu, .ready:
            scrollScenery(dt)
        case .playing:
            scrollScenery(dt)
            updateTowers(dt)
            updateHero(dt)
            if state == .playing { checkTowerCollisions() }
        case .dying:
            updateHero(dt)
        case .paused, .gameOver:
            break
        }
    }

    private func scroll(_ tiles: [SKSpriteNode], by dx: CGFloat, tileWidth: CGFloat) {
        for tile in tiles {
            tile.position.x -= dx
            if tile.position.x <= -tileWidth {
                tile.position.x += tileWidth * CGFloat(tiles.count)
            }
        }
    }

    private func scrollScenery(_ dt: CGFloat) {
        let speed = GameConfig.speed(for: score)
        scroll(groundTiles, by: speed * dt, tileWidth: Textures.groundSize.width)
        scroll(nearHillTiles, by: speed * 0.45 * dt, tileWidth: Textures.hillWidth)
        scroll(farHillTiles, by: speed * 0.2 * dt, tileWidth: Textures.hillWidth)
        for cloud in clouds {
            cloud.position.x -= speed * 0.1 * cloud.xScale * dt
            if cloud.frame.maxX < 0 {
                cloud.position.x = size.width + cloud.frame.width / 2 + CGFloat.random(in: 0...80)
                cloud.position.y = CGFloat.random(in: size.height * 0.5...size.height * 0.9)
            }
        }
    }

    private func updateHero(_ dt: CGFloat) {
        heroVelocity = max(heroVelocity + GameConfig.gravity * dt, GameConfig.maxFallSpeed)
        hero.position.y += heroVelocity * dt

        let ceiling = size.height + 20
        if hero.position.y > ceiling {
            hero.position.y = ceiling
            heroVelocity = min(heroVelocity, 0)
        }

        // Tilt up when rising, nose-dive when falling.
        let target: CGFloat = heroVelocity > 0 ? 0.42 : max(-1.45, 0.42 + heroVelocity / 380)
        let rate: CGFloat = heroVelocity > 0 ? 18 : 7
        hero.zRotation += (target - hero.zRotation) * min(1, dt * rate)

        let floor = GameConfig.groundHeight + GameConfig.heroHitRadius
        if hero.position.y <= floor {
            hero.position.y = floor
            if state == .playing {
                die()
            }
            if state == .dying {
                finishDying()
            }
        }
    }

    // MARK: - Towers

    private func updateTowers(_ dt: CGFloat) {
        let dx = GameConfig.speed(for: score) * dt
        distanceSinceSpawn += dx
        if distanceSinceSpawn >= GameConfig.towerSpacing {
            distanceSinceSpawn -= GameConfig.towerSpacing
            spawnTower()
        }

        for tower in towers {
            tower.node.position.x -= dx
            if !tower.scored && tower.node.position.x < hero.position.x {
                tower.scored = true
                addPoint()
            }
        }

        towers.removeAll { tower in
            if tower.node.position.x < -GameConfig.towerCapWidth {
                tower.node.removeFromParent()
                return true
            }
            return false
        }
    }

    private func spawnTower() {
        let gap = GameConfig.gap(for: score)
        let minCenter = GameConfig.groundHeight + 60 + gap / 2
        let maxCenter = size.height - 70 - gap / 2
        var center = CGFloat.random(in: minCenter...maxCenter)
        if let last = lastGapCenter {
            center = min(max(center, last - GameConfig.maxGapShift), last + GameConfig.maxGapShift)
        }
        lastGapCenter = center

        let node = SKNode()
        node.position = CGPoint(x: size.width + GameConfig.towerCapWidth / 2 + 8, y: 0)
        node.zPosition = 0

        let capSize = CGSize(width: GameConfig.towerCapWidth, height: GameConfig.towerCapHeight)
        let gapBottom = center - gap / 2
        let gapTop = center + gap / 2

        // Bottom tower (grows up from behind the ground)
        let bottomHeight = gapBottom - (GameConfig.groundHeight - 10)
        let bottomBody = SKSpriteNode(texture: Textures.towerBodySlice(height: bottomHeight),
                                      size: CGSize(width: GameConfig.towerBodyWidth, height: bottomHeight))
        bottomBody.anchorPoint = CGPoint(x: 0.5, y: 1)
        bottomBody.position = CGPoint(x: 0, y: gapBottom)
        let bottomCap = SKSpriteNode(texture: Textures.towerCap, size: capSize)
        bottomCap.anchorPoint = CGPoint(x: 0.5, y: 1)
        bottomCap.position = CGPoint(x: 0, y: gapBottom)
        bottomCap.zPosition = 1

        // Top tower (hangs down from above the screen)
        let topHeight = size.height - gapTop + 40
        let topBody = SKSpriteNode(texture: Textures.towerBodySlice(height: topHeight),
                                   size: CGSize(width: GameConfig.towerBodyWidth, height: topHeight))
        topBody.anchorPoint = CGPoint(x: 0.5, y: 0)
        topBody.position = CGPoint(x: 0, y: gapTop)
        let topCap = SKSpriteNode(texture: Textures.towerCap, size: capSize)
        topCap.anchorPoint = CGPoint(x: 0.5, y: 0)
        topCap.position = CGPoint(x: 0, y: gapTop)
        topCap.zPosition = 1

        [bottomBody, bottomCap, topBody, topCap].forEach { node.addChild($0) }
        world.addChild(node)
        towers.append(Tower(node: node, gapCenter: center, gap: gap))
    }

    private func clearTowers() {
        towers.forEach { $0.node.removeFromParent() }
        towers.removeAll()
    }

    private func checkTowerCollisions() {
        let r = GameConfig.heroHitRadius
        let p = hero.position
        let bodyHalf = GameConfig.towerBodyWidth / 2
        let capHalf = GameConfig.towerCapWidth / 2
        let capH = GameConfig.towerCapHeight

        for tower in towers {
            let x = tower.node.position.x
            guard abs(x - p.x) <= capHalf + r else { continue }
            let gapBottom = tower.gapCenter - tower.gap / 2
            let gapTop = tower.gapCenter + tower.gap / 2
            let rects = [
                CGRect(x: x - bodyHalf, y: -100, width: bodyHalf * 2, height: gapBottom + 100),
                CGRect(x: x - capHalf, y: gapBottom - capH, width: capHalf * 2, height: capH),
                CGRect(x: x - bodyHalf, y: gapTop, width: bodyHalf * 2, height: 2000),
                CGRect(x: x - capHalf, y: gapTop, width: capHalf * 2, height: capH)
            ]
            if rects.contains(where: { circle(center: p, radius: r, intersects: $0) }) {
                die()
                return
            }
        }
    }

    private func circle(center c: CGPoint, radius r: CGFloat, intersects rect: CGRect) -> Bool {
        let nearestX = min(max(c.x, rect.minX), rect.maxX)
        let nearestY = min(max(c.y, rect.minY), rect.maxY)
        let dx = c.x - nearestX
        let dy = c.y - nearestY
        return dx * dx + dy * dy < r * r
    }

    // MARK: - Scoring & death

    private func addPoint() {
        score += 1
        scoreLabel.text = "\(score)"
        scoreLabel.removeAction(forKey: "pop")
        scoreLabel.setScale(1)
        scoreLabel.run(.sequence([.scale(to: 1.18, duration: 0.06), .scale(to: 1.0, duration: 0.1)]), withKey: "pop")
        AudioManager.shared.play(.score, volume: 0.6)
        scoreHaptic.selectionChanged()
    }

    private func die() {
        guard state == .playing else { return }
        state = .dying
        AudioManager.shared.play(.hit)
        hitHaptic.impactOccurred()
        hero.removeAction(forKey: "wings")
        flashScreen()
        shakeWorld()

        let onGround = hero.position.y <= GameConfig.groundHeight + GameConfig.heroHitRadius + 0.5
        if !onGround {
            heroVelocity = min(heroVelocity, 150)
            run(.sequence([.wait(forDuration: 0.2), .onMain { AudioManager.shared.play(.fall, volume: 0.7) }]))
        }
    }

    private func finishDying() {
        guard state == .dying else { return }
        state = .gameOver

        let isNewBest = score > ScoreStore.best
        if isNewBest { ScoreStore.best = score }
        ScoreStore.gamesPlayed += 1
        GameCenterManager.shared.submit(score: score)

        scoreLabel.run(.fadeOut(withDuration: 0.2))
        let finalScore = score
        run(.sequence([.wait(forDuration: 0.45), .onMain { [weak self] in
            self?.setOverlay(self?.makeGameOverOverlay(score: finalScore, isNewBest: isNewBest))
            self?.maybeAskForReview(score: finalScore)
        }]))
    }

    private func flashScreen() {
        let flash = SKSpriteNode(color: .white, size: size)
        flash.anchorPoint = .zero
        flash.zPosition = 300
        flash.alpha = 0
        addChild(flash)
        flash.run(.sequence([.fadeAlpha(to: 0.75, duration: 0.04), .fadeOut(withDuration: 0.25), .removeFromParent()]))
    }

    private func shakeWorld() {
        var actions: [SKAction] = []
        for _ in 0..<6 {
            actions.append(.moveBy(x: CGFloat.random(in: -8...8), y: CGFloat.random(in: -8...8), duration: 0.03))
        }
        actions.append(.move(to: .zero, duration: 0.03))
        world.run(.sequence(actions))
    }

    private func maybeAskForReview(score: Int) {
        // Ask rarely, and only after a good run. iOS also rate-limits this prompt itself.
        guard score >= 8, [12, 40, 120].contains(ScoreStore.gamesPlayed) else { return }
        run(.sequence([.wait(forDuration: 1.5), .onMain { [weak self] in
            guard let windowScene = self?.view?.window?.windowScene else { return }
            AppStore.requestReview(in: windowScene)
        }]))
    }

    // MARK: - Overlays

    private func smallLabel(_ text: String, size fontSize: CGFloat, color: UIColor) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = text
        label.fontSize = fontSize
        label.fontColor = color
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        return label
    }

    private func soundIcon() -> SKTexture {
        Textures.symbol(AudioManager.shared.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill", pointSize: 22)
    }

    private func makeSoundButton() -> ButtonNode {
        ButtonNode(texture: Textures.roundButton, size: CGSize(width: 62, height: 62),
                   icon: soundIcon()) { [weak self] button in
            AudioManager.shared.setMuted(!AudioManager.shared.isMuted)
            if let icon = self?.soundIcon() {
                button.iconNode?.texture = icon
                button.iconNode?.size = icon.size()
            }
        }
    }

    private func makeMenuOverlay() -> SKNode {
        let node = SKNode()
        let w = size.width
        let h = size.height

        let title = OutlinedLabel(text: "SKY HOP", fontSize: 64, color: .white, outline: Palette.ink,
                                  outlineWidth: 4, shadowOffset: 6)
        title.position = CGPoint(x: w / 2, y: h * 0.75)
        let rise = SKAction.moveBy(x: 0, y: 8, duration: 1.1)
        rise.timingMode = .easeInEaseOut
        title.run(.repeatForever(.sequence([rise, rise.reversed()])))
        node.addChild(title)

        let subtitle = OutlinedLabel(text: "Help Sprout fly!", fontSize: 20, color: Palette.cream,
                                     outline: Palette.ink, outlineWidth: 2, shadowOffset: 2)
        subtitle.position = CGPoint(x: w / 2, y: h * 0.75 - 54)
        node.addChild(subtitle)

        let play = ButtonNode(texture: Textures.playButtonLarge, size: CGSize(width: 190, height: 72),
                              title: "PLAY", fontSize: 32) { [weak self] _ in
            self?.startReady()
        }
        play.position = CGPoint(x: w / 2, y: h * 0.36)
        node.addChild(play)

        let best = OutlinedLabel(text: "BEST  \(ScoreStore.best)", fontSize: 22, color: .white,
                                 outline: Palette.ink, outlineWidth: 2.5, shadowOffset: 2)
        best.position = CGPoint(x: w / 2, y: h * 0.36 - 70)
        node.addChild(best)

        let buttonY = GameConfig.groundHeight + 48
        let soundButton = makeSoundButton()
        soundButton.position = CGPoint(x: w / 2 - 48, y: buttonY)
        node.addChild(soundButton)

        let ranks = ButtonNode(texture: Textures.roundButton, size: CGSize(width: 62, height: 62),
                               icon: Textures.symbol("trophy.fill", pointSize: 22)) { _ in
            GameCenterManager.shared.showLeaderboard()
        }
        ranks.position = CGPoint(x: w / 2 + 48, y: buttonY)
        node.addChild(ranks)

        return node
    }

    private func makeReadyOverlay() -> SKNode {
        let node = SKNode()
        let title = OutlinedLabel(text: "Get Ready!", fontSize: 50, color: Palette.sun, outline: Palette.ink,
                                  outlineWidth: 4, shadowOffset: 5)
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.74)
        node.addChild(title)

        let hint = OutlinedLabel(text: "Tap anywhere to flap", fontSize: 22, color: .white, outline: Palette.ink,
                                 outlineWidth: 2.5, shadowOffset: 2)
        hint.position = CGPoint(x: size.width / 2, y: size.height * 0.4)
        node.addChild(hint)

        let ring = SKSpriteNode(texture: Textures.ring)
        ring.position = heroStart
        ring.run(.repeatForever(.sequence([
            .group([.scale(to: 1.7, duration: 0.9), .fadeOut(withDuration: 0.9)]),
            .group([.scale(to: 1, duration: 0), .fadeIn(withDuration: 0)])
        ])))
        node.addChild(ring)
        return node
    }

    private func makePausedOverlay() -> SKNode {
        let node = SKNode()
        let dim = SKSpriteNode(color: UIColor(white: 0, alpha: 0.35), size: size)
        dim.anchorPoint = .zero
        node.addChild(dim)

        let title = OutlinedLabel(text: "PAUSED", fontSize: 54, color: .white, outline: Palette.ink,
                                  outlineWidth: 4, shadowOffset: 5)
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.6)
        node.addChild(title)

        let hint = OutlinedLabel(text: "Tap to resume", fontSize: 22, color: .white, outline: Palette.ink,
                                 outlineWidth: 2.5, shadowOffset: 2)
        hint.position = CGPoint(x: size.width / 2, y: size.height * 0.6 - 60)
        node.addChild(hint)
        return node
    }

    private func medalTexture(for score: Int) -> SKTexture {
        switch score {
        case GameConfig.platinumScore...: return Textures.medals[.platinum] ?? Textures.medalEmpty
        case GameConfig.goldScore...: return Textures.medals[.gold] ?? Textures.medalEmpty
        case GameConfig.silverScore...: return Textures.medals[.silver] ?? Textures.medalEmpty
        case GameConfig.bronzeScore...: return Textures.medals[.bronze] ?? Textures.medalEmpty
        default: return Textures.medalEmpty
        }
    }

    private func makeGameOverOverlay(score: Int, isNewBest: Bool) -> SKNode {
        let node = SKNode()
        let w = size.width
        let h = size.height

        // Title drops in
        let title = OutlinedLabel(text: "GAME OVER", fontSize: 50, color: Palette.coral, outline: Palette.ink,
                                  outlineWidth: 4, shadowOffset: 5)
        title.position = CGPoint(x: w / 2, y: h * 0.74 + 30)
        title.alpha = 0
        let drop = SKAction.moveBy(x: 0, y: -30, duration: 0.3)
        drop.timingMode = .easeOut
        title.run(.group([.fadeIn(withDuration: 0.25), drop]))
        node.addChild(title)

        // Score panel slides up
        let panelY = h * 0.53
        let panel = SKSpriteNode(texture: Textures.panel, size: Textures.panelSize)
        panel.position = CGPoint(x: w / 2, y: -Textures.panelSize.height)
        let slide = SKAction.move(to: CGPoint(x: w / 2, y: panelY), duration: 0.4)
        slide.timingMode = .easeOut
        panel.run(.sequence([.wait(forDuration: 0.15), slide]))
        node.addChild(panel)

        let medalCaption = smallLabel("MEDAL", size: 16, color: Palette.panelText)
        medalCaption.position = CGPoint(x: -85, y: 56)
        panel.addChild(medalCaption)

        let medal = SKSpriteNode(texture: medalTexture(for: score), size: CGSize(width: 72, height: 72))
        medal.position = CGPoint(x: -85, y: -8)
        panel.addChild(medal)

        let scoreCaption = smallLabel("SCORE", size: 16, color: Palette.panelText)
        scoreCaption.position = CGPoint(x: 70, y: 56)
        panel.addChild(scoreCaption)

        let scoreValue = OutlinedLabel(text: "0", fontSize: 34, color: .white, outline: Palette.ink,
                                       outlineWidth: 3, shadowOffset: 2)
        scoreValue.position = CGPoint(x: 70, y: 24)
        panel.addChild(scoreValue)

        let bestCaption = smallLabel("BEST", size: 16, color: Palette.panelText)
        bestCaption.position = CGPoint(x: 70, y: -18)
        panel.addChild(bestCaption)

        let bestValue = OutlinedLabel(text: "\(ScoreStore.best)", fontSize: 34, color: .white, outline: Palette.ink,
                                      outlineWidth: 3, shadowOffset: 2)
        bestValue.position = CGPoint(x: 70, y: -52)
        panel.addChild(bestValue)

        if isNewBest {
            let badge = SKSpriteNode(texture: Textures.newBadge, size: CGSize(width: 54, height: 24))
            badge.position = CGPoint(x: 118, y: -18)
            let label = smallLabel("NEW", size: 14, color: .white)
            badge.addChild(label)
            badge.setScale(0)
            badge.run(.sequence([.wait(forDuration: 1.2), .scale(to: 1.2, duration: 0.12), .scale(to: 1, duration: 0.08)]))
            panel.addChild(badge)
        }

        // Count the score up
        if score > 0 {
            let duration = min(0.8, 0.05 * Double(score))
            scoreValue.run(.sequence([
                .wait(forDuration: 0.55),
                .customOnMain(duration: duration) { node, elapsed in
                    let value = Int((CGFloat(score) * elapsed / CGFloat(duration)).rounded(.down))
                    (node as? OutlinedLabel)?.text = "\(min(value, score))"
                },
                .onMain { [weak scoreValue] in scoreValue?.text = "\(score)" }
            ]))
        }

        // Buttons (enabled after a beat so a frantic tap doesn't skip the screen)
        let buttonY = panelY - Textures.panelSize.height / 2 - 52
        let play = ButtonNode(texture: Textures.playButton, size: CGSize(width: 140, height: 62),
                              title: "PLAY", fontSize: 26) { [weak self] _ in
            self?.startReady()
        }
        play.position = CGPoint(x: w / 2 - 78, y: buttonY)

        let ranks = ButtonNode(texture: Textures.ranksButton, size: CGSize(width: 140, height: 62),
                               title: "RANKS", fontSize: 26) { _ in
            GameCenterManager.shared.showLeaderboard()
        }
        ranks.position = CGPoint(x: w / 2 + 78, y: buttonY)

        let sound = makeSoundButton()
        sound.position = CGPoint(x: w / 2, y: max(GameConfig.groundHeight + 40, buttonY - 82))

        for button in [play, ranks, sound] {
            button.isEnabled = false
            button.alpha = 0
            button.run(.sequence([.wait(forDuration: 0.6), .fadeIn(withDuration: 0.2), .onMain { [weak button] in button?.isEnabled = true }]))
            node.addChild(button)
        }

        return node
    }
}
