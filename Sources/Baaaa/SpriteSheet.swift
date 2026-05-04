import AppKit
import CoreGraphics

/// Loads the eSheep sprite sheet and produces individual frame images.
///
/// The sheet is a 16×11 grid of 40×40 tiles. The original PNG uses
/// magenta (255,0,255) as the transparency colour, which we strip on
/// load.
final class SpriteSheet {
    static let shared = SpriteSheet()

    static let columns = 16
    static let rows = 11
    static let tileSize = 40

    private let processed: CGImage
    private var cache: [CacheKey: CGImage] = [:]

    private struct CacheKey: Hashable { let index: Int; let flipped: Bool }

    private init() {
        guard let url = SpriteSheet.locateSpriteSheet(),
              let data = try? Data(contentsOf: url),
              let provider = CGDataProvider(data: data as CFData),
              let raw = CGImage(
                pngDataProviderSource: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
              )
        else {
            fatalError("Baaaa: could not load esheep.png from bundle")
        }
        processed = SpriteSheet.removingMagenta(from: raw)
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

    /// Locate `esheep.png` regardless of how the binary is packaged.
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

    private static func removingMagenta(from image: CGImage) -> CGImage {
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

        var i = 0
        while i < pixels.count {
            let r = pixels[i]
            let g = pixels[i + 1]
            let b = pixels[i + 2]
            // Match magenta with a small tolerance so anti-aliased pixels
            // also become transparent.
            if r > 240 && g < 16 && b > 240 {
                pixels[i] = 0
                pixels[i + 1] = 0
                pixels[i + 2] = 0
                pixels[i + 3] = 0
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
