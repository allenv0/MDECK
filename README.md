
<div align="center">

# MDECK

</div>

<div align="center">

<img src="app-assets/MDECK2.png" width="128" alt="MDECK icon" />

---

**A native macOS MP3/WAV/FLAC player with a retro MiniDisc-inspired aesthetic.** 

</div>

<div align="center">
    <img src="assets/MD-Anim.gif" alt="demo animation" width="700" />
</div>

<div align="center">

```bash
brew tap allenv0/mdeck && brew trust allenv0/mdeck && brew install --cask mdeck
```

</div>


## New Features:

- Persistent playlists
- Artwork support
- EqualizerView

**More color themes**

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

## Install

Via Homebrew:

```bash
brew tap allenv0/mdeck
brew trust allenv0/mdeck
brew install --cask mdeck
```

> MDeck is ad-hoc signed (not notarized), so Gatekeeper blocks the first
> launch. Right-click `MDECK.app` in Finder and choose **Open**, or run
> `xattr -dr com.apple.quarantine /Applications/MDECK.app`.

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

Note: *MDECK is a fork of [DotMP3](https://github.com/moerdowo/DotMP3)*

## License

MIT
