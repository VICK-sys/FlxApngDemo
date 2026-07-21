# FlxApngDemo

Animated PNG (APNG) playback for [HaxeFlixel](https://haxeflixel.com/) — as far as we can tell, the first APNG player in the Haxe ecosystem. Drop an `.png` animation into `assets/apng`, load it with one line of code, and it plays.

## Why APNG?

APNG is the modern successor to GIF, and it's what platforms like Discord use for animated stickers. Compared to GIF it has two big advantages:

- **Full color** — GIF is limited to 256 colors per frame; APNG uses the full 16 million.
- **Real transparency** — GIF pixels are either fully solid or fully invisible, which is why GIFs have those crunchy white edges on transparent backgrounds. APNG has 256 levels of transparency, so soft shadows, glows, and anti-aliased edges look right on any background.

Nothing in the Haxe world could play them — until now.

## Showing an APNG in your game

```haxe
var sticker = new ApngSprite(0, 0, AssetPaths.mysticker__png);
sticker.screenCenter();
add(sticker);
```

That's it. The decoder is written entirely in Haxe, so it works the same on every target with no native libraries to install. If a file is broken and can't be read, you get a small magenta square and a log message instead of a crash.

Animations that are set to play a limited number of times stop on their last frame and fire `onComplete`, just like the format intends.

### Playback controls

- `speed` — playback rate multiplier (clamped to a sane 0.05×–10×)
- `paused` — freeze and unfreeze
- `reversed` — play backwards
- `apngFrame` — read or jump to a specific frame
- `onLoop` / `onComplete` — run your own code when the animation loops or finishes its play count

Decoded animations are cached and shared — load the same file in ten places and the decode work happens once. `ApngCache.clear()` frees the memory, and `ApngCache.enableAutoClear()` does it automatically on every screen change (sprites that survive the change quietly reload themselves).

## Setting up your project

Two things beyond copying the three source files (`ApngDecoder.hx`, `ApngCache.hx`, `ApngSprite.hx`):

1. Add the format library: `haxelib install format`, and `<haxelib name="format" />` in `Project.xml`.
2. APNG files must reach the game as raw bytes, not as pre-decoded images (the toolchain treats `.png` as a regular image by default and would flatten it to its first frame). Keep them in their own folder, declared like this:

```xml
<assets path="assets" exclude="apng" />
<assets path="assets/apng" rename="assets/apng" type="binary" />
```

## What's supported

- Truecolor with or without transparency, greyscale, and indexed/palette color (including palette transparency) — 8-bit depth
- All APNG dispose and blend modes, variable per-frame timing, finite play counts
- Plain non-animated PNGs load too and show as a single frame, so you can use `ApngSprite` everywhere without caring which kind of file you have

Not supported (rare in practice, and the decoder tells you clearly): interlaced PNGs and 16-bit color depth.

Frames are unpacked once into a single sprite sheet, so very long animations produce a very large image — the game logs a warning past 4096px, where older or mobile graphics cards start refusing textures.

Each animation honors its exact per-frame timing (APNG allows every frame to display for a different duration), not an averaged frame rate.

Real decode costs, measured on the slowest target (HTML5, where the unpacking runs in pure JavaScript): sticker-sized animations decode in 4–11ms; a 5-second full-color 240px video clip (82 frames, 6.6MB) takes about half a second, once, when first loaded. The decode time is printed to the console for every file so you can check your own assets. Keep clips to a few seconds and pre-load big ones somewhere the pause won't be felt.

## Running the demo

```
lime test html5
```

The demo plays four files over a checkerboard (so you can see the transparency is real): a full-color video clip, a smooth-alpha bouncing ball, an indexed-color square, and a static PNG. SPACE pauses, LEFT/RIGHT change speed, R reverses.
