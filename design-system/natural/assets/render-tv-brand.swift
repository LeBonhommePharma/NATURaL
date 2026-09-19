// Native export only: preserves the approved transparent bloom's pixels and silhouette.
// Run from repository root: swift design-system/natural/assets/render-tv-brand.swift
import Foundation
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let catalog = root.appendingPathComponent("BonhommeTV/Assets.xcassets/AppIcon.brandassets")
let bloomURL = root.appendingPathComponent("design-system/natural/assets/approved/bloom-foreground.png")
let bloom = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithURL(bloomURL as CFURL, nil)!, 0, nil)!
let space = CGColorSpace(name: CGColorSpace.sRGB)!
var context: CGContext!

let info: [String: Any] = ["author": "com.natural.BonhommeTV", "version": 1]
func directory(_ url: URL) throws { try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true) }
func json(_ value: [String: Any], at url: URL) throws {
    try directory(url)
    try JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys]).write(to: url.appendingPathComponent("Contents.json"))
}
func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> CGColor {
    CGColor(colorSpace: space, components: [red / 255, green / 255, blue / 255, 1])!
}
func background(_ rect: CGRect) {
    context.setFillColor(color(8, 9, 26)); context.fill(rect)
    let gradient = CGGradient(colorsSpace: space, colors: [color(25, 18, 47), color(8, 9, 26)] as CFArray, locations: [0, 1])!
    let center = CGPoint(x: rect.midX, y: rect.midY)
    context.drawRadialGradient(gradient, startCenter: center, startRadius: 0,
                               endCenter: center, endRadius: rect.width * 0.55, options: [.drawsAfterEndLocation])
}
func render(width: Int, height: Int, alpha: Bool, at url: URL, drawing: (CGRect) -> Void) throws {
    context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                        bytesPerRow: width * 4, space: space,
                        bitmapInfo: (alpha ? CGImageAlphaInfo.premultipliedLast : CGImageAlphaInfo.noneSkipLast).rawValue)!
    context.interpolationQuality = .high
    drawing(CGRect(x: 0, y: 0, width: width, height: height))
    let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, context.makeImage()!, nil)
    guard CGImageDestinationFinalize(destination) else { fatalError("Cannot export " + url.path) }
    context = nil
}
func drawBloom(_ rect: CGRect) {
    // Source is square. 76% canvas height reserves at least 12% clear padding;
    // the artwork's original transparent border adds further focus/parallax space.
    let side = rect.height * 0.76
    context.draw(bloom, in: CGRect(x: rect.midX - side / 2, y: rect.midY - side / 2, width: side, height: side))
}
func imageSet(at url: URL, width: Int, height: Int, scales: [Int], alpha: Bool,
              drawing: (CGRect) -> Void) throws {
    try directory(url)
    var images: [[String: Any]] = []
    for scale in scales {
        let filename = "image@\(scale)x.png"
        try render(width: width * scale, height: height * scale, alpha: alpha,
                   at: url.appendingPathComponent(filename), drawing: drawing)
        images.append(["idiom": "tv", "scale": "\(scale)x", "filename": filename])
    }
    try json(["info": info, "images": images], at: url)
}
var assets: [[String: Any]] = []
for (name, width, height, scales) in [("App Icon - Small", 400, 240, [1, 2]), ("App Icon - Large", 1280, 768, [1])] {
    let stackName = name + ".imagestack"
    let stack = catalog.appendingPathComponent(stackName)
    var layers: [[String: String]] = []
    for (layerName, alpha) in [("Foreground", true), ("Background", false)] {
        let filename = layerName + ".imagestacklayer"
        let layer = stack.appendingPathComponent(filename)
        try json(["info": info], at: layer)
        try imageSet(at: layer.appendingPathComponent("Content.imageset"), width: width, height: height,
                     scales: scales, alpha: alpha, drawing: alpha ? drawBloom : background)
        layers.append(["filename": filename])
    }
    try json(["info": info, "layers": layers], at: stack)
    assets.append(["idiom": "tv", "size": "\(width)x\(height)", "role": "primary-app-icon", "filename": stackName])
}
for (name, width, role) in [("Top Shelf Image", 1920, "top-shelf-image"), ("Top Shelf Image Wide", 2320, "top-shelf-image-wide")] {
    let filename = name + ".imageset"
    try imageSet(at: catalog.appendingPathComponent(filename), width: width, height: 720, scales: [1, 2], alpha: false) { rect in
        background(rect)
        let scale = rect.height / 720
        let side = 490 * scale
        context.draw(bloom, in: CGRect(x: rect.midX - 550 * scale, y: rect.midY - side / 2, width: side, height: side))
        let title = NSAttributedString(string: "NATURaL", attributes: [
            NSAttributedString.Key(kCTFontAttributeName as String): CTFontCreateWithName("HelveticaNeue-Medium" as CFString, 120 * scale, nil),
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): color(228, 227, 245),
            NSAttributedString.Key(kCTKernAttributeName as String): 2 * scale
        ])
        let line = CTLineCreateWithAttributedString(title)
        let bounds = CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds])
        context.textPosition = CGPoint(x: rect.midX - 55 * scale, y: rect.midY - bounds.height / 2 - bounds.minY)
        CTLineDraw(line, context)

    }
    assets.append(["idiom": "tv", "size": "\(width)x720", "role": role, "filename": filename])
}
try json(["info": info, "assets": assets], at: catalog)
// Review contact image is outside the compiled catalog.
try render(width: 800, height: 480, alpha: false,
           at: root.appendingPathComponent("design-system/natural/assets/tv-icon-preview.png")) { rect in
    background(rect); drawBloom(rect)
}
print("Exported TV brand assets and preview; Xcode actool + device focus review still required.")
