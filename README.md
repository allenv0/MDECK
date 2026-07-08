<div align="center">

<img src="app-assets/MDECK-mac.png" width="128" alt="MDECK icon" />

# MDECK

**A native macOS MP3/WAV/FLAC player with a retro MiniDisc-inspired aesthetic.** 

*A fork of [DotMP3](https://github.com/moerdowo/DotMP3)*


</div>

<div align="center">

![MDECK playing a track](app-assets/g.png)

![MDECK playing a track](app-assets/g1.png)

![MDECK playing a track](app-assets/g2.png)

![MDECK playing a track](app-assets/g3.png)



</div>


## Requirements

- macOS 14.0+
- Xcode 16+ (Swift 5)
- [XcodeGen](https://github.com/yonatankra/xcodegen) (`brew install xcodegen`) to generate
  the project

## Build & run

```bash
xcodegen generate
open MDECK.xcodeproj   # then ⌘R in Xcode
```

Or from the command line:

```bash
xcodegen generate
xcodebuild -project MDECK.xcodeproj -scheme MDECK -configuration Debug build
```

## Usage

- **Add music** — drag audio files into the window, or use **File → Open Files…** (⌘O).
- Supported formats: MP3, M4A, AAC, WAV, AIFF, FLAC.

## License

MIT
