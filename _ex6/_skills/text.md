---
name: "text"
description: "Use for anything to do with richtext/font rendering, or localization"
---

## Localization

Global `loc` is `localization.localize` (set in main.lua).
`loc(text, variables?, metadata?)` returns an Interpolator object.

Rules:
- loc() MUST be called at load-time (top of file, as constants). Never at runtime.
- The returned Interpolator is callable: `MY_LOC({n = 5})` to interpolate at runtime.
- `tostring(interpolator)` returns the translated string (with no variables).

Pattern:
```lua
-- At top of file (load-time):
local MY_TEXT = loc("You have %{n} soldiers")
local FIRE_TEXT = loc("Fire", {}, {context = "Verb, as in to shoot"})

-- At runtime (draw/update):
text.printRich(MY_TEXT({n = count}), font, x, y, limit, "left")
```

Interpolation syntax: `%{varname}` or `%{varname:.2f}` (format specifier).
Escape with `%%{...}`.

The `metadata.context` field helps translators disambiguate identical strings.
You should generally ALWAYS use it:
```lua
loc("Fire", {}, {context = "Verb, as in to shoot"})
loc("Fire", {}, {context = "Noun, as in a campfire"})
```

Pipeline:
- `localization.load(strings)` ingests translated key-value pairs.
- `localization.dump()` exports all encountered strings for extraction.
- Missing translations in non-English log a warning.


## Richtext

Module: `src/modules/richtext/exports.lua`, required as `richtext` in g.lua.
All text in the game should use richtext for rendering.

### API

Drawing:
- `text.printRich(txt, font, x, y, limit, align)` — main draw function. Supports transforms.
- `text.printRichCentered(txt, font, x, y, limit, align)` — centered variant.
- `text.printRichContained(txt, font, x, y, w, h)` — fits text inside a box (with wrapping).
- `text.printRichContainedNoWrap(txt, font, x, y, w, h)` — fits text inside a box (no wrapping, scales down).

Measuring:
- `text.getWidth(txt, font)` — width of text.
- `text.getWrap(txt, font, maxwidth)` — returns width, lineCount.

Parsing (rarely needed directly):
- `text.parseRichText(txt)` — returns ParsedText (cached via LRU).

Registration:
- `text.defineEffect(name, renderFunc, opts?)` — register a custom effect.
- `text.defineImage(name, texture, quad?)` — register an image for inline use.

### Tags

Tags use `{tagname}...{/tagname}` syntax. Args are `key=value`.

Built-in effects:
- `{color r=1 g=0 b=0}` or `{c r=1 g=0 b=0}` — set text color. Args: r, g, b, a.
- `{outline r=0 g=0 b=0}` or `{o r=0 g=0 b=0}` — outline. Args: r, g, b, a, thickness.
- `{wavy freq=2 amp=3}` or `{w freq=2 amp=3}` — wavy animation (per-character). Args: freq, amp, k.
  - k controls phase offset between characters. k=0 means all chars bob in sync.
- `{rainbow}` — rainbow color cycling (per-character).

Custom effects are registered via `text.defineEffect`. Example (rarity colors):
```lua
richtext.defineEffect("RARE_COLOR_LIGHT", function(args, x, y, context, next)
    love.graphics.setColor(r, g, b, a)
    next(context.textOrDrawable, x, y)
end)
-- Usage: "{RARE_COLOR_LIGHT}Rare Sword{/RARE_COLOR_LIGHT}"
```

### Inline Images

Any image loaded via `g.loadImagesFrom` is auto-registered for richtext.
Use `{image_name}` (no closing tag) to embed an image inline with text.
Scale with `{image_name scale=2}`.


## Fonts

Two font families, both pixel-art (loaded as "mono", no anti-aliasing):
- `g.getBigFont(size)` — "Smart 9h.ttf". Use for titles, headers.
- `g.getSmallFont(size)` — "Match 7h.ttf". Use for body text, descriptions.

Rules:
- Size MUST be a multiple of 16 (asserted). Common sizes: 16, 32, 48.
- Both fonts use `unifont` as fallback for non-Latin glyphs.
- Fonts are cached internally; safe to call repeatedly.

Typical usage:
```lua
local TITLE_FONT = g.getBigFont(32)
local BODY_FONT = g.getSmallFont(16)
```
