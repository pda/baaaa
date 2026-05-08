import CoreGraphics
import Testing
@testable import Baaaa

@Test func naturalSpriteTraitsAreGeneratedFromTheBaseSheet() {
    #expect(SpriteTraits.WoolTone.allCases == [.original, .ivory, .cream, .warmCream, .silver, .ash, .golden])
    #expect(SpriteTraits.PointMarking.allCases == [.original, .blackPoints])
    #expect(SpriteTraits.HornTone.allCases == [.original, .taupe, .grey, .umber])

    let sheets = [
        SpriteSheet(traits: .original),
        SpriteSheet(traits: SpriteTraits(wool: .ivory, points: .original, horns: .original)),
        SpriteSheet(traits: SpriteTraits(wool: .silver, points: .original, horns: .original)),
        SpriteSheet(traits: SpriteTraits(wool: .golden, points: .original, horns: .original)),
        SpriteSheet(traits: SpriteTraits(wool: .cream, points: .blackPoints, horns: .taupe)),
    ]

    for sheet in sheets {
        let tile = sheet.tile(index: 3, flipped: false)
        #expect(tile?.width == SpriteSheet.tileSize)
        #expect(tile?.height == SpriteSheet.tileSize)

        let flipped = sheet.tile(index: 3, flipped: true)
        #expect(flipped?.width == SpriteSheet.tileSize)
        #expect(flipped?.height == SpriteSheet.tileSize)
    }

    let naturalTraits = SpriteTraits(wool: .silver, points: .blackPoints, horns: .taupe)
    if let originalTile = SpriteSheet(traits: .original).tile(index: 0, flipped: false),
       let naturalTile = SpriteSheet(traits: naturalTraits).tile(index: 0, flipped: false) {
        #expect(rgbaBytes(originalTile) != rgbaBytes(naturalTile))
        #expect(alphaBytes(originalTile) == alphaBytes(naturalTile))
    } else {
        #expect(Bool(false), "Expected original and natural sprite tiles to load")
    }
}

private func rgbaBytes(_ image: CGImage) -> [UInt8] {
    let bytesPerRow = image.width * 4
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
    var pixels = [UInt8](repeating: 0, count: bytesPerRow * image.height)

    guard let ctx = pixels.withUnsafeMutableBytes({ buffer -> CGContext? in
        CGContext(
            data: buffer.baseAddress,
            width: image.width,
            height: image.height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        )
    }) else { return [] }

    ctx.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    return pixels
}

private func alphaBytes(_ image: CGImage) -> [UInt8] {
    rgbaBytes(image).enumerated().compactMap { offset, byte in
        offset % 4 == 3 ? byte : nil
    }
}
