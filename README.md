# FlxApngDemo

Animated PNG (APNG) playback for [HaxeFlixel](https://haxeflixel.com/). Put an APNG in `assets/apng`, load it with `ApngSprite`, and it plays.

APNG advantages over GIF:

- Full 24-bit color instead of a 256-color palette
- 256 levels of transparency instead of on/off, so anti-aliased edges and soft shadows render correctly

The decoder is written entirely in Haxe and works the same on every target. No native libraries are required.

## Usage

```haxe
var sticker = new ApngSprite(0, 0, AssetPaths.mysticker__png);
sticker.screenCenter();
add(sticker);
```

A file that fails to decode shows a magenta placeholder and logs a warning instead of crashing.

Animations with a finite play count stop on their last frame and fire `onComplete`.

### Playback properties

- `speed` — playback rate multiplier (clamped to 0.05–10)
- `paused` — pause and resume
- `reversed` — play backwards
- `apngFrame` — read or set the current frame
- `onLoop` / `onComplete` — signals fired on each loop and when a finite play count finishes

Decoded animations are cached and shared: loading the same file multiple times decodes it once. `ApngCache.clear()` frees the memory, and `ApngCache.enableAutoClear()` clears automatically on every state switch. Sprites that survive a state switch reload their file on the next update.

## Project setup

1. Copy `ApngDecoder.hx`, `ApngCache.hx`, and `ApngSprite.hx` into your source folder.
2. Install the format library (`haxelib install format`) and add `<haxelib name="format" />` to `Project.xml`.
3. APNG files must be packaged as raw bytes. Lime treats `.png` as a regular image by default, which flattens an APNG to its first frame. Keep APNGs in a dedicated folder declared as binary:

```xml
<assets path="assets" exclude="apng" />
<assets path="assets/apng" rename="assets/apng" type="binary" />
```

## Supported

- Truecolor, greyscale, and indexed color, with or without transparency (including palette transparency) — 8-bit depth
- All APNG dispose and blend modes
- Exact per-frame timing, including variable frame delays
- Finite play counts
- Plain non-animated PNGs, shown as a single frame

Not supported: interlaced PNGs and 16-bit color depth. Both fail with a clear error message.

## Performance

Frames are unpacked once into a single sprite sheet. A warning is logged when a sheet exceeds 4096px, the texture size limit of older and mobile GPUs.

Decode times measured on HTML5 (the slowest target): 4–11ms for sticker-sized files, about 470ms for a 5-second 240px video clip (82 frames, 6.6MB). Decoding happens once per file, on first load, and the time is printed to the console for each file. Load large files at a point where a pause is acceptable.

## Demo

```
lime test html5
```

The demo plays four files over a checkerboard background: a full-color video clip, a bouncing ball with smooth alpha, an indexed-color square, and a static PNG. SPACE pauses, LEFT/RIGHT change speed, R reverses.
