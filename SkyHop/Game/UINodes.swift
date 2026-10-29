import SpriteKit
import UIKit

/// A label with a solid outline and drop shadow, built from stacked SKLabelNodes.
final class OutlinedLabel: SKNode {
    private var labels: [SKLabelNode] = []

    var text: String {
        didSet { labels.forEach { $0.text = text } }
    }

    init(text: String, fontSize: CGFloat, color: UIColor, outline: UIColor,
         outlineWidth: CGFloat = 3, shadowOffset: CGFloat = 4, fontName: String = "AvenirNext-Heavy") {
        self.text = text
        super.init()

        func make(_ fill: UIColor, at offset: CGPoint) {
            let label = SKLabelNode(fontNamed: fontName)
            label.text = text
            label.fontSize = fontSize
            label.fontColor = fill
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.position = offset
            addChild(label)
            labels.append(label)
        }

        if shadowOffset > 0 {
            make(outline, at: CGPoint(x: 0, y: -(outlineWidth + shadowOffset)))
        }
        let d = outlineWidth
        let diagonal = outlineWidth * 0.72
        let offsets = [CGPoint(x: d, y: 0), CGPoint(x: -d, y: 0), CGPoint(x: 0, y: d), CGPoint(x: 0, y: -d),
                       CGPoint(x: diagonal, y: diagonal), CGPoint(x: -diagonal, y: diagonal),
                       CGPoint(x: diagonal, y: -diagonal), CGPoint(x: -diagonal, y: -diagonal)]
        for offset in offsets { make(outline, at: offset) }
        make(color, at: .zero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}

/// A tappable sprite button. The scene handles touches and calls `action`.
final class ButtonNode: SKSpriteNode {
    let action: @MainActor (ButtonNode) -> Void
    var isEnabled = true
    private(set) var iconNode: SKSpriteNode?

    init(texture: SKTexture, size: CGSize, title: String? = nil, fontSize: CGFloat = 28,
         icon: SKTexture? = nil, action: @escaping @MainActor (ButtonNode) -> Void) {
        self.action = action
        super.init(texture: texture, color: .clear, size: size)

        // The texture has a 9-pt "3D" lip at the bottom; center content on the face.
        let faceOffset: CGFloat = 4
        if let title {
            let label = OutlinedLabel(text: title, fontSize: fontSize, color: .white, outline: Palette.ink,
                                      outlineWidth: 2.5, shadowOffset: 0)
            label.position = CGPoint(x: 0, y: faceOffset)
            label.zPosition = 1
            addChild(label)
        }
        if let icon {
            let iconNode = SKSpriteNode(texture: icon)
            iconNode.position = CGPoint(x: 0, y: faceOffset)
            iconNode.zPosition = 1
            addChild(iconNode)
            self.iconNode = iconNode
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func setPressed(_ pressed: Bool) {
        removeAction(forKey: "press")
        run(.scale(to: pressed ? 0.93 : 1.0, duration: 0.06), withKey: "press")
    }
}

extension SKAction {
    /// `SKAction.run` that is safe to use with main-actor code under any Swift concurrency setting.
    /// SpriteKit always runs action blocks on the main thread.
    static func onMain(_ block: @escaping @MainActor () -> Void) -> SKAction {
        .run {
            MainActor.assumeIsolated { block() }
        }
    }

    static func customOnMain(duration: TimeInterval,
                             _ block: @escaping @MainActor (SKNode, CGFloat) -> Void) -> SKAction {
        .customAction(withDuration: duration) { node, elapsed in
            MainActor.assumeIsolated { block(node, elapsed) }
        }
    }
}
