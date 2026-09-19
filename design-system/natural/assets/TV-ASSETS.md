# NATURaL Apple TV brand assets

The shipping `BonhommeTV/Assets.xcassets/AppIcon.brandassets` uses the approved bloom as a transparent foreground over a separately rendered opaque midnight background. The original flat TV catalog is retained in `archive/tv-flat-AppIcon.appiconset` outside the compiled asset catalog.

- Home icon: 400 × 240 and 800 × 480 pixels, with foreground and background layers at both scales.
- Store icon: 1280 × 768 pixels, with the same two layers.
- Static Top Shelf: 1920 × 720 and 3840 × 1440 pixels.
- Wide static Top Shelf: 2320 × 720 and 4640 × 1440 pixels.
- Stack order is foreground first, opaque background last. There are no duplicate flattened layers.
- Source square is fitted within 76% of icon canvas height, retaining its original alpha padding. The offline check requires at least 10% fully transparent edge padding and nonempty artwork. This is our conservative composition rule, not a claimed numeric Apple requirement.
- Top Shelf includes the product name; it has no simulated buttons, prices, language-dependent claims, or promotional copy.

The approved foreground was extracted with image generation from the approved bloom. Its original generated pixels are preserved in `approved/bloom-foreground.png`. The native CoreGraphics/CoreText exporter performs resizing and composition; it does not segment or repaint the artwork. The subtle edge highlight was reviewed on midnight at runtime size. `tv-icon-preview.png` is a composite for review only and is not a shipping icon layer.

Regenerate from the repository root on macOS:

```sh
swift design-system/natural/assets/render-tv-brand.swift
python3 scripts/test_submission_assets.py
python3 scripts/validate-submission.py --include-macos
```

The metadata, PNG pixels, safe-zone alpha, and mutation regression tests pass locally without Xcode. These checks do not validate `actool`, signed packaging, store acceptance, or focus/parallax on Apple TV. The tvOS Release CI job and an actual Apple TV focus/Top Shelf check remain necessary.

Format references: [Apple brand assets schema](https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_ref-Asset_Catalog_Format/BrandAssetsType.html), [image stacks](https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_ref-Asset_Catalog_Format/ImageStackType.html), [embedded stack layers](https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_ref-Asset_Catalog_Format/ImageStackLayerType.html), [Top Shelf guidance](https://developer.apple.com/design/human-interface-guidelines/top-shelf).
