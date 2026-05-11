import AppKit
import CoreGraphics

/// Loads the eSheep sprite sheet and produces individual frame images.
///
/// The sheet is a 16×11 grid of 40×40 tiles. Per-sheep traits are
/// generated in memory by remapping the source sheet's exact pixel
/// colours.
fileprivate struct RGB: Hashable {
    let r: UInt8
    let g: UInt8
    let b: UInt8

    init(_ r: UInt8, _ g: UInt8, _ b: UInt8) {
        self.r = r
        self.g = g
        self.b = b
    }

    init(_ hex: Int) {
        self.r = UInt8((hex >> 16) & 0xff)
        self.g = UInt8((hex >> 8) & 0xff)
        self.b = UInt8(hex & 0xff)
    }
}

fileprivate struct WoolPalette {
    let highlight: RGB
    let light: RGB
    let mid: RGB
    let dark: RGB
}

fileprivate struct PointPalette {
    let highlight: RGB
    let light: RGB
    let mid: RGB
    let dark: RGB
}

fileprivate struct HornPalette {
    let highlight: RGB
    let mid: RGB
    let dark: RGB
}

struct SpriteTraits: Equatable {
    enum WoolTone: CaseIterable {
        case original
        case ivory
        case cream
        case warmCream
        case silver
        case ash
        case golden
    }

    enum PointMarking: CaseIterable {
        case original
        case blackPoints
    }

    enum HornTone: CaseIterable {
        case original
        case taupe
        case grey
        case umber
    }

    let wool: WoolTone
    let points: PointMarking
    let horns: HornTone

    static let original = SpriteTraits(wool: .original, points: .original, horns: .original)

    static func random() -> SpriteTraits {
        var generator = SystemRandomNumberGenerator()
        return random(using: &generator)
    }

    static func random<R: RandomNumberGenerator>(using generator: inout R) -> SpriteTraits {
        let wool: WoolTone = weightedChoice([
            (.original, 42),
            (.ivory, 18),
            (.cream, 16),
            (.warmCream, 10),
            (.silver, 8),
            (.ash, 6),
            (.golden, 1),
        ], using: &generator)

        let points: PointMarking = weightedChoice([
            (.original, 82),
            (.blackPoints, 18),
        ], using: &generator)

        return SpriteTraits(
            wool: wool,
            points: points,
            horns: points == .blackPoints
                ? weightedChoice([(.original, 60), (.taupe, 24), (.grey, 16)], using: &generator)
                : .original
        )
    }

    private static func weightedChoice<T, R: RandomNumberGenerator>(
        _ options: [(value: T, weight: Int)],
        using generator: inout R
    ) -> T {
        let total = options.reduce(0) { $0 + $1.weight }
        precondition(total > 0, "weightedChoice requires at least one positive weight")
        var roll = Int.random(in: 0..<total, using: &generator)
        for option in options {
            roll -= option.weight
            if roll < 0 { return option.value }
        }
        return options[options.count - 1].value
    }
}

fileprivate extension SpriteTraits {
    var colorMap: [RGB: RGB] {
        if self == .original {
            return [:]
        }
        return Self.palette(wool: wool.palette, points: points.palette, horns: horns.palette)
    }

    private static func palette(wool: WoolPalette, points: PointPalette, horns: HornPalette) -> [RGB: RGB] {
        var colors: [RGB: RGB] = [:]

        for source in [RGB(0xFFFCD9), RGB(0xFEFBD8), RGB(0xFFFBD8)] {
            colors[source] = wool.highlight
        }
        for source in [RGB(0xFFF691), RGB(0xFEF590), RGB(0xFFFF00)] {
            colors[source] = wool.light
        }
        for source in [RGB(0xC2BC7A), RGB(0xC1BB79)] {
            colors[source] = wool.mid
        }
        for source in [RGB(0xA39E67), RGB(0xA29D66)] {
            colors[source] = wool.dark
        }

        colors[RGB(0xFFDCC7)] = points.highlight
        colors[RGB(0xFFC4A1)] = points.light
        colors[RGB(0xFFA875)] = points.mid
        colors[RGB(0xFF904F)] = points.mid
        colors[RGB(0xFF6B2B)] = points.dark

        colors[RGB(0xFF7AFF)] = horns.highlight
        colors[RGB(0xB300B3)] = horns.mid
        colors[RGB(0x730073)] = horns.dark

        return colors
    }
}

fileprivate extension SpriteTraits.WoolTone {
    var palette: WoolPalette {
        switch self {
        case .original:
            return WoolPalette(
                highlight: RGB(0xFFFCD9),
                light: RGB(0xFFF691),
                mid: RGB(0xC2BC7A),
                dark: RGB(0xA39E67)
            )
        case .ivory:
            return WoolPalette(
                highlight: RGB(0xFFFDF0),
                light: RGB(0xF4E9B8),
                mid: RGB(0xD1C38A),
                dark: RGB(0x948A62)
            )
        case .cream:
            return WoolPalette(
                highlight: RGB(0xFFF7D8),
                light: RGB(0xEBDDA2),
                mid: RGB(0xC5B678),
                dark: RGB(0x86794E)
            )
        case .warmCream:
            return WoolPalette(
                highlight: RGB(0xFFF1C7),
                light: RGB(0xE9CD82),
                mid: RGB(0xB99C53),
                dark: RGB(0x7C6537)
            )
        case .silver:
            return WoolPalette(
                highlight: RGB(0xF2F3EC),
                light: RGB(0xDDDCD0),
                mid: RGB(0xB8B7A8),
                dark: RGB(0x828276)
            )
        case .ash:
            return WoolPalette(
                highlight: RGB(0xD6D7CC),
                light: RGB(0xB7B9AC),
                mid: RGB(0x898C80),
                dark: RGB(0x5E645C)
            )
        case .golden:
            return WoolPalette(
                highlight: RGB(0xFFF0A8),
                light: RGB(0xE7BE48),
                mid: RGB(0xAE7D25),
                dark: RGB(0x715016)
            )
        }
    }
}

fileprivate extension SpriteTraits.PointMarking {
    var palette: PointPalette {
        switch self {
        case .original:
            return PointPalette(
                highlight: RGB(0xFFDCC7),
                light: RGB(0xFFC4A1),
                mid: RGB(0xFFA875),
                dark: RGB(0xFF6B2B)
            )
        case .blackPoints:
            return PointPalette(
                highlight: RGB(0x777D80),
                light: RGB(0x555C5F),
                mid: RGB(0x333A3E),
                dark: RGB(0x1E2428)
            )
        }
    }
}

fileprivate extension SpriteTraits.HornTone {
    var palette: HornPalette {
        switch self {
        case .original:
            return HornPalette(
                highlight: RGB(0xFF7AFF),
                mid: RGB(0xB300B3),
                dark: RGB(0x730073)
            )
        case .taupe:
            return HornPalette(
                highlight: RGB(0xD0B898),
                mid: RGB(0xA58561),
                dark: RGB(0x6B543B)
            )
        case .grey:
            return HornPalette(
                highlight: RGB(0xD0D2CE),
                mid: RGB(0x9A9D96),
                dark: RGB(0x5A5D57)
            )
        case .umber:
            return HornPalette(
                highlight: RGB(0xC49362),
                mid: RGB(0x8B5F3A),
                dark: RGB(0x573A23)
            )
        }
    }
}

final class SpriteSheet {
    private static let sourceImage: CGImage = loadSourceImage()

    static let shared = SpriteSheet(traits: .original)

    static func randomVariant() -> SpriteSheet {
        SpriteSheet(traits: .random())
    }

    static let columns = 16
    static let rows = 11
    static let tileSize = 40

    let traits: SpriteTraits
    private let processed: CGImage
    private var cache: [CacheKey: CGImage] = [:]

    private struct CacheKey: Hashable { let index: Int; let flipped: Bool }

    init(traits: SpriteTraits = .original) {
        self.traits = traits
        processed = SpriteSheet.processing(Self.sourceImage, using: traits)
    }

    private static func loadSourceImage() -> CGImage {
        guard let url = SpriteSheet.locateSpriteSheet(),
              let data = try? Data(contentsOf: url),
              let provider = CGDataProvider(data: data as CFData),
              let image = CGImage(
                pngDataProviderSource: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
              )
        else {
            fatalError("Baaaa: could not load esheep.png from bundle")
        }
        return image
    }

    /// Returns the cropped (and optionally horizontally flipped) tile at
    /// the given linear sprite index, where 0 is the top-left tile,
    /// indices increase left-to-right then top-to-bottom.
    func tile(index: Int, flipped: Bool) -> CGImage? {
        let key = CacheKey(index: index, flipped: flipped)
        if let cached = cache[key] { return cached }

        let col = index % Self.columns
        let row = index / Self.columns
        let rect = CGRect(
            x: col * Self.tileSize,
            y: row * Self.tileSize,
            width: Self.tileSize,
            height: Self.tileSize
        )
        guard var cropped = processed.cropping(to: rect) else { return nil }
        if flipped, let mirrored = SpriteSheet.flippedHorizontally(cropped) {
            cropped = mirrored
        }
        cache[key] = cropped
        return cropped
    }

    /// Locate a sprite sheet regardless of how the binary is packaged.
    ///
    /// SwiftPM's generated `Bundle.module` accessor only looks for the
    /// resource bundle next to `Bundle.main.bundleURL` (i.e. directly
    /// inside `Baaaa.app/`) or at a hard-coded absolute path that
    /// points at the developer's `.build/` directory. Neither exists
    /// inside a properly laid-out `.app` on another machine, so we
    /// look in `Contents/Resources/` first and only fall back to
    /// `Bundle.module` (whose initializer would otherwise crash).
    private static func locateSpriteSheet() -> URL? {
        let appResources = Bundle.main.bundleURL
            .appendingPathComponent("Contents/Resources/Baaaa_Baaaa.bundle/esheep.png")
        if FileManager.default.fileExists(atPath: appResources.path) {
            return appResources
        }
        return Bundle.module.url(forResource: "esheep", withExtension: "png")
    }

    // MARK: - Image processing

    private static func processing(_ image: CGImage, using traits: SpriteTraits) -> CGImage {
        let width = image.width
        let height = image.height
        let bytesPerRow = width * 4
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        var pixels = [UInt8](repeating: 0, count: bytesPerRow * height)

        guard let ctx = pixels.withUnsafeMutableBytes({ buffer -> CGContext? in
            CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            )
        }) else { return image }

        ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        let colorMap = traits.colorMap
        var i = 0
        while i < pixels.count {
            let r = pixels[i]
            let g = pixels[i + 1]
            let b = pixels[i + 2]
            let a = pixels[i + 3]
            // Match magenta with a small tolerance so anti-aliased pixels
            // also become transparent.
            if r > 240 && g < 16 && b > 240 {
                pixels[i] = 0
                pixels[i + 1] = 0
                pixels[i + 2] = 0
                pixels[i + 3] = 0
            } else if a > 0, let replacement = colorMap[RGB(r, g, b)] {
                pixels[i] = replacement.r
                pixels[i + 1] = replacement.g
                pixels[i + 2] = replacement.b
            }
            i += 4
        }

        guard let provider = CGDataProvider(data: Data(pixels) as CFData),
              let out = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
              )
        else { return image }
        return out
    }

    private static func flippedHorizontally(_ image: CGImage) -> CGImage? {
        let width = image.width
        let height = image.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        ctx.translateBy(x: CGFloat(width), y: 0)
        ctx.scaleBy(x: -1, y: 1)
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return ctx.makeImage()
    }
}
