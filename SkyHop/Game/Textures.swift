import SpriteKit
import UIKit

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: alpha)
    }
}

enum Palette {
    static let skyTop = UIColor(hex: 0x58B7EA)
    static let skyBottom = UIColor(hex: 0xCFF1F7)
    static let ink = UIColor(hex: 0x3A2414)
    static let cream = UIColor(hex: 0xFFF4DC)
    static let sun = UIColor(hex: 0xFFC845)
    static let coral = UIColor(hex: 0xFF7A59)
    static let panelText = UIColor(hex: 0xC2703D)
    static let heroOutline = UIColor(hex: 0x1E5E48)
}

/// Every sprite in the game is drawn in code, so there are no image files to license.
enum Textures {

    // MARK: - Rendering helpers

    private static func render(_ size: CGSize, scale: CGFloat = 3, _ draw: (CGContext) -> Void) -> SKTexture {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            draw(context.cgContext)
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    private static func ellipse(_ ctx: CGContext, center: CGPoint, size: CGSize, angle: CGFloat = 0,
                                fill: UIColor, stroke: UIColor? = nil, lineWidth: CGFloat = 2) {
        ctx.saveGState()
        ctx.translateBy(x: center.x, y: center.y)
        ctx.rotate(by: angle)
        let path = UIBezierPath(ovalIn: CGRect(x: -size.width / 2, y: -size.height / 2,
                                               width: size.width, height: size.height))
        fill.setFill()
        path.fill()
        if let stroke {
            stroke.setStroke()
            path.lineWidth = lineWidth
            path.stroke()
        }
        ctx.restoreGState()
    }

    // MARK: - Hero ("Sprout")

    static let heroFrames: [SKTexture] = [
        heroFrame(wingAngle: -0.55, wingY: 26),
        heroFrame(wingAngle: 0.0, wingY: 31),
        heroFrame(wingAngle: 0.55, wingY: 35),
        heroFrame(wingAngle: 0.0, wingY: 31)
    ]

    private static func heroFrame(wingAngle: CGFloat, wingY: CGFloat) -> SKTexture {
        render(GameConfig.heroSize) { ctx in
            let outline = Palette.heroOutline

            // Sprout on top
            let stem = UIBezierPath()
            stem.move(to: CGPoint(x: 30, y: 12))
            stem.addQuadCurve(to: CGPoint(x: 30, y: 5), controlPoint: CGPoint(x: 28.5, y: 8))
            outline.setStroke()
            stem.lineWidth = 2.5
            stem.lineCapStyle = .round
            stem.stroke()
            ellipse(ctx, center: CGPoint(x: 25, y: 6), size: CGSize(width: 11, height: 6), angle: 0.45,
                    fill: UIColor(hex: 0x8EE06A), stroke: outline, lineWidth: 2)
            ellipse(ctx, center: CGPoint(x: 35, y: 6), size: CGSize(width: 11, height: 6), angle: -0.45,
                    fill: UIColor(hex: 0x8EE06A), stroke: outline, lineWidth: 2)

            // Body
            let bodyRect = CGRect(x: 10, y: 11, width: 40, height: 40)
            let body = UIBezierPath(ovalIn: bodyRect)
            UIColor(hex: 0x63D3A4).setFill()
            body.fill()

            // Belly (clipped to body)
            ctx.saveGState()
            body.addClip()
            UIColor(hex: 0xE3FAEC).setFill()
            UIBezierPath(ovalIn: CGRect(x: 18, y: 31, width: 30, height: 22)).fill()
            ctx.restoreGState()

            outline.setStroke()
            body.lineWidth = 3
            body.stroke()

            // Cheek
            ellipse(ctx, center: CGPoint(x: 39, y: 37), size: CGSize(width: 8, height: 5),
                    fill: UIColor(hex: 0xFF9AAE, alpha: 0.85))

            // Eye
            ellipse(ctx, center: CGPoint(x: 37, y: 25), size: CGSize(width: 14, height: 14),
                    fill: .white, stroke: outline, lineWidth: 2)
            ellipse(ctx, center: CGPoint(x: 39, y: 25.5), size: CGSize(width: 7, height: 7),
                    fill: UIColor(hex: 0x1B2A2E))
            ellipse(ctx, center: CGPoint(x: 40.4, y: 23.8), size: CGSize(width: 2.6, height: 2.6), fill: .white)

            // Beak
            let beak = UIBezierPath()
            beak.move(to: CGPoint(x: 47, y: 28))
            beak.addLine(to: CGPoint(x: 55, y: 31))
            beak.addLine(to: CGPoint(x: 47, y: 34))
            beak.close()
            UIColor(hex: 0xFFB23E).setFill()
            beak.fill()
            outline.setStroke()
            beak.lineWidth = 2
            beak.lineJoinStyle = .round
            beak.stroke()

            // Wing
            ellipse(ctx, center: CGPoint(x: 17, y: wingY), size: CGSize(width: 18, height: 11), angle: wingAngle,
                    fill: UIColor(hex: 0x48B98A), stroke: outline, lineWidth: 2.5)
        }
    }

    // MARK: - Towers

    static let towerBodyHeight: CGFloat = 800

    static let towerBody: SKTexture = render(CGSize(width: GameConfig.towerBodyWidth, height: towerBodyHeight), scale: 2) { ctx in
        let w = GameConfig.towerBodyWidth
        let h = towerBodyHeight
        UIColor(hex: 0xD9734E).setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))

        UIColor(hex: 0xB95C3B).setFill()
        let rowHeight: CGFloat = 20
        var y: CGFloat = 0
        var row = 0
        while y < h {
            ctx.fill(CGRect(x: 0, y: y, width: w, height: 2))
            var x: CGFloat = (row % 2 == 0) ? 19 : 38
            while x < w {
                ctx.fill(CGRect(x: x, y: y, width: 2, height: rowHeight))
                x += 38
            }
            y += rowHeight
            row += 1
        }

        UIColor(white: 1, alpha: 0.22).setFill()
        ctx.fill(CGRect(x: 8, y: 0, width: 9, height: h))
        UIColor(white: 0, alpha: 0.16).setFill()
        ctx.fill(CGRect(x: w - 16, y: 0, width: 12, height: h))

        Palette.ink.setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: 3, height: h))
        ctx.fill(CGRect(x: w - 3, y: 0, width: 3, height: h))
    }

    static let towerCap: SKTexture = render(CGSize(width: GameConfig.towerCapWidth, height: GameConfig.towerCapHeight)) { ctx in
        let size = CGSize(width: GameConfig.towerCapWidth, height: GameConfig.towerCapHeight)
        let rect = CGRect(x: 1.5, y: 1.5, width: size.width - 3, height: size.height - 3)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 6)
        UIColor(hex: 0xEC8D63).setFill()
        path.fill()

        ctx.saveGState()
        path.addClip()
        UIColor(white: 1, alpha: 0.28).setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: size.width, height: 8))
        UIColor(white: 1, alpha: 0.18).setFill()
        ctx.fill(CGRect(x: 10, y: 0, width: 10, height: size.height))
        UIColor(white: 0, alpha: 0.18).setFill()
        ctx.fill(CGRect(x: 0, y: size.height - 8, width: size.width, height: 8))
        ctx.restoreGState()

        Palette.ink.setStroke()
        path.lineWidth = 3
        path.stroke()
    }

    static func towerBodySlice(height: CGFloat) -> SKTexture {
        let fraction = min(1, max(0.01, height / towerBodyHeight))
        return SKTexture(rect: CGRect(x: 0, y: 0, width: 1, height: fraction), in: towerBody)
    }

    // MARK: - Scenery

    static let sky: SKTexture = render(CGSize(width: 8, height: 800), scale: 1) { ctx in
        let colors = [Palette.skyTop.cgColor, Palette.skyBottom.cgColor] as CFArray
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
            ctx.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: 800), options: [])
        }
    }

    static let groundSize = CGSize(width: 336, height: GameConfig.groundHeight)

    static let ground: SKTexture = render(groundSize, scale: 2) { ctx in
        let w = groundSize.width
        let h = groundSize.height
        UIColor(hex: 0xE3BC74).setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))

        UIColor(hex: 0x74C95C).setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: 20))
        UIColor(hex: 0x5EB24A).setFill()
        for i in 0...14 {
            let x0 = CGFloat(i) * 24
            let stripe = UIBezierPath()
            stripe.move(to: CGPoint(x: x0, y: 0))
            stripe.addLine(to: CGPoint(x: x0 + 12, y: 0))
            stripe.addLine(to: CGPoint(x: x0 + 4, y: 20))
            stripe.addLine(to: CGPoint(x: x0 - 8, y: 20))
            stripe.close()
            stripe.fill()
        }
        UIColor(hex: 0x9BE07D).setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: 3))
        UIColor(hex: 0x3E8A3A).setFill()
        ctx.fill(CGRect(x: 0, y: 20, width: w, height: 4))
        UIColor(hex: 0xCFA35E).setFill()
        ctx.fill(CGRect(x: 0, y: 24, width: w, height: 6))

        UIColor(hex: 0xC9995A).setFill()
        for i in 0..<36 {
            let x = CGFloat((i * 53) % 320) + 8
            let y = CGFloat(38 + (i * 29) % 66)
            UIBezierPath(ovalIn: CGRect(x: x, y: y, width: 6, height: 4)).fill()
        }
    }

    static let hillWidth: CGFloat = 600

    private static func hills(height: CGFloat, base: CGFloat, waves: [(amp: CGFloat, freq: CGFloat, phase: CGFloat)],
                              color: UIColor) -> SKTexture {
        render(CGSize(width: hillWidth, height: height), scale: 2) { _ in
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 0, y: height))
            var x: CGFloat = 0
            while x <= hillWidth {
                var y = base
                for wave in waves {
                    y += wave.amp * sin(2 * .pi * x / hillWidth * wave.freq + wave.phase)
                }
                path.addLine(to: CGPoint(x: x, y: height - y))
                x += 4
            }
            path.addLine(to: CGPoint(x: hillWidth, y: height))
            path.close()
            color.setFill()
            path.fill()
        }
    }

    static let farHills = hills(height: 180, base: 110,
                                waves: [(28, 2, 0), (16, 5, 1.3)],
                                color: UIColor(hex: 0xA9DCC4))

    static let nearHills = hills(height: 120, base: 62,
                                 waves: [(20, 3, 0.5), (10, 7, 0)],
                                 color: UIColor(hex: 0x7DC596))

    static let cloudSize = CGSize(width: 150, height: 76)

    static let cloud: SKTexture = render(cloudSize, scale: 2) { ctx in
        let puffs: [(CGFloat, CGFloat, CGFloat)] = [(40, 45, 22), (70, 33, 28), (105, 42, 24), (126, 50, 16)]
        func drawPuffs(dy: CGFloat, color: UIColor) {
            color.setFill()
            for (x, y, r) in puffs {
                UIBezierPath(ovalIn: CGRect(x: x - r, y: y - r + dy, width: r * 2, height: r * 2)).fill()
            }
            UIBezierPath(roundedRect: CGRect(x: 26, y: 44 + dy, width: 110, height: 24), cornerRadius: 12).fill()
        }
        drawPuffs(dy: 4, color: UIColor(hex: 0xD8EEF6))
        drawPuffs(dy: 0, color: .white)
    }

    // MARK: - UI

    private static func button(size: CGSize, face: UIColor, shade: UIColor) -> SKTexture {
        render(size) { _ in
            let radius = min(18, size.height / 2)
            let shadow = UIBezierPath(roundedRect: CGRect(x: 1.5, y: 7.5, width: size.width - 3, height: size.height - 9),
                                      cornerRadius: radius)
            shade.setFill()
            shadow.fill()
            Palette.ink.setStroke()
            shadow.lineWidth = 3
            shadow.stroke()

            let faceRect = CGRect(x: 1.5, y: 1.5, width: size.width - 3, height: size.height - 9)
            let facePath = UIBezierPath(roundedRect: faceRect, cornerRadius: radius)
            face.setFill()
            facePath.fill()
            UIColor(white: 1, alpha: 0.3).setFill()
            UIBezierPath(roundedRect: CGRect(x: 10, y: 6, width: size.width - 20, height: (size.height - 9) * 0.3),
                         cornerRadius: 8).fill()
            Palette.ink.setStroke()
            facePath.lineWidth = 3
            facePath.stroke()
        }
    }

    static let playButtonLarge = button(size: CGSize(width: 190, height: 72),
                                        face: UIColor(hex: 0xFF8A3D), shade: UIColor(hex: 0xC85E1C))
    static let playButton = button(size: CGSize(width: 140, height: 62),
                                   face: UIColor(hex: 0xFF8A3D), shade: UIColor(hex: 0xC85E1C))
    static let ranksButton = button(size: CGSize(width: 140, height: 62),
                                    face: UIColor(hex: 0x5AA9E6), shade: UIColor(hex: 0x2F78B3))
    static let roundButton = button(size: CGSize(width: 62, height: 62),
                                    face: UIColor(hex: 0x5AA9E6), shade: UIColor(hex: 0x2F78B3))

    static let panelSize = CGSize(width: 300, height: 180)

    static let panel: SKTexture = render(panelSize) { _ in
        let outer = UIBezierPath(roundedRect: CGRect(x: 1.5, y: 1.5, width: panelSize.width - 3, height: panelSize.height - 3),
                                 cornerRadius: 20)
        Palette.cream.setFill()
        outer.fill()
        Palette.ink.setStroke()
        outer.lineWidth = 3
        outer.stroke()
        let inner = UIBezierPath(roundedRect: CGRect(x: 9, y: 9, width: panelSize.width - 18, height: panelSize.height - 18),
                                 cornerRadius: 14)
        UIColor(hex: 0xF0D9AE).setStroke()
        inner.lineWidth = 2
        inner.stroke()
    }

    enum MedalTier { case bronze, silver, gold, platinum }

    private static func medal(fill: UIColor?, rim: UIColor) -> SKTexture {
        render(CGSize(width: 72, height: 72)) { _ in
            let outer = UIBezierPath(ovalIn: CGRect(x: 3, y: 3, width: 66, height: 66))
            rim.setFill()
            outer.fill()
            Palette.ink.setStroke()
            outer.lineWidth = 3
            outer.stroke()
            guard let fill else { return }
            fill.setFill()
            UIBezierPath(ovalIn: CGRect(x: 11, y: 11, width: 50, height: 50)).fill()

            let star = UIBezierPath()
            let center = CGPoint(x: 36, y: 37)
            for i in 0..<10 {
                let radius: CGFloat = i % 2 == 0 ? 17 : 7.5
                let angle = -CGFloat.pi / 2 + CGFloat(i) * .pi / 5
                let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
                if i == 0 { star.move(to: point) } else { star.addLine(to: point) }
            }
            star.close()
            UIColor(white: 1, alpha: 0.9).setFill()
            star.fill()
        }
    }

    static let medalEmpty = medal(fill: nil, rim: UIColor(hex: 0xF0D9AE))

    static let medals: [MedalTier: SKTexture] = [
        .bronze: medal(fill: UIColor(hex: 0xD8894B), rim: UIColor(hex: 0xB0662E)),
        .silver: medal(fill: UIColor(hex: 0xC9D3DC), rim: UIColor(hex: 0x98A6B3)),
        .gold: medal(fill: UIColor(hex: 0xFFCF3F), rim: UIColor(hex: 0xE0A10C)),
        .platinum: medal(fill: UIColor(hex: 0xBFF2F0), rim: UIColor(hex: 0x6CC9D0))
    ]

    static let newBadge: SKTexture = render(CGSize(width: 54, height: 24)) { _ in
        let path = UIBezierPath(roundedRect: CGRect(x: 1, y: 1, width: 52, height: 22), cornerRadius: 8)
        UIColor(hex: 0xE5484D).setFill()
        path.fill()
        Palette.ink.setStroke()
        path.lineWidth = 2
        path.stroke()
    }

    static let ring: SKTexture = render(CGSize(width: 70, height: 70)) { _ in
        let path = UIBezierPath(ovalIn: CGRect(x: 4, y: 4, width: 62, height: 62))
        UIColor.white.setStroke()
        path.lineWidth = 4
        path.stroke()
    }

    /// Renders an SF Symbol into a plain bitmap texture.
    static func symbol(_ name: String, pointSize: CGFloat, color: UIColor = .white) -> SKTexture {
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .heavy)
        guard let image = UIImage(systemName: name, withConfiguration: config)?
            .withTintColor(color, renderingMode: .alwaysOriginal) else {
            return SKTexture()
        }
        return render(image.size) { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }
}
