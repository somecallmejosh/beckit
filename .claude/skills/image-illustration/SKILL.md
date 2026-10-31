---
name: image-illustration
description: Make, redraw or fix beckit illustrations (the gray line-art drawings with one floating teal accent) so they match the brand. Use whenever a task adds, replaces, regenerates, retraces or edits an SVG drawing in app/assets/images, or asks for "an image", "a drawing", "an illustration" or "art" for a page.
---

# beckit illustrations

The drawings are a core part of the beckit brand. Every drawing must look as if the illustrator of the
thinking-trap set (`app/assets/images/traps/`) drew it. The trap drawings are the reference; when in doubt,
put the new drawing next to them and compare.

## The rules

### Character
- An adult with a big round head and short black hair with a small tufted cowlick
- Dot eyes (curved lines when resting), a small hooked "c" nose line, a "c" ear, a small simple smile
- Rounded, mitten-like hands; plain white long-sleeved top; gray trousers
- Skin (face, ears, hands, bare feet) is light gray `#B6B6B3`. Mid gray `#8E8E8B` is for trousers, shoes and props, never the main character's skin; the only mid-gray skin is a second person in a group scene, as in some traps. The step drawings were corrected from mid to light skin for this reason.
- Low detail, simple shapes, calm expressions

### Line, color and finish
- Thick, smooth, slightly wobbly ink line `#262626`
- Flat fills only: white, light `#B6B6B3`, mid `#8E8E8B`. No gradients, texture, hatching or shading.
- Transparent background, generous white space around the figure
- **Rough edge, subtle.** Here and there a gray fill slips a few pixels past its outline, leaving a thin
  light-gray sliver on the paper (behind an ear, under a chin, beside a hand). A handful per drawing, only
  beside gray fills, never around white shapes. `traps/emotional-reasoning.svg` is the benchmark for how much.
  Heavier blotches were rejected as "way too exaggerated".

### The teal accent
- Exactly one teal `#0F9488` thing per drawing, near the figure, with two or three small ink sparkles
- **Its outline is stationary; the fill floats inside it.** The accent's ink outline lives in the main ink
  layer and never moves. Only the teal fill and the ink details it encloses (a face, a swirl) sit in
  `<g class="accent">` and bob, drifting a little past the outline like the misregistered fills.
  A drawing whose whole accent (outline included) moves is wrong.
- Animation, identical in every file:
  ```css
  .accent{transform-box:fill-box;transform-origin:50% 60%;animation:float 6s ease-in-out infinite}
  @keyframes float{0%,100%{transform:translate(0,0) rotate(0)}50%{transform:translate(0,-22px) rotate(-3deg)}}
  @media (prefers-reduced-motion:reduce){.accent{animation:none}}
  ```
- Some older accents have no outline (the hug heart, the mental-filter sun). That's allowed, but new
  drawings should give the accent an outline.

### SVG structure
Potrace paths at `scale(0.250000,-0.250000)`, one group per color, bottom to top:
light `#B6B6B3` (fills plus the rough edge), mid `#8E8E8B`, ink `#262626` (including the accent outline),
then `<g class="accent">` holding teal `#0F9488` and the enclosed ink details.

## Families

| Family | Folder | Canvas | Dark mode |
| --- | --- | --- | --- |
| Thinking traps (reference) | `traps/` | 1024x1536 | no |
| Landing | `landing/hero.svg`, `band.svg` | 1024x1536, 2160x900 | no |
| Greetings, insights | `greetings/`, `insights.svg` | 1380x920 | no |
| Be kind (footer, random) | `be-kind/`, listed in `ApplicationHelper::KIND_WORDS` | 1200x1000 | no |
| Entry steps | `steps/` | 1000x1000 | yes: `.ink .mid .light .solid .teal` classes recolor under `prefers-color-scheme: dark` |
| Plant milestones | `milestones/` | 900x900 | yes, same classes |

When editing a dark-mode-aware file, keep its classes on every group you add (`class="light"` and so on).

## Workflow

Needs ImageMagick (`magick`), `potrace`, `rsvg-convert`, `ruby`, `curl` and `OPENAI_API_KEY`.

1. **Brief the scene.** One sentence each for the pose, the few props (light gray), and the one teal accent
   ("Above them floats a teal cloud with a tiny calm ink face."). Nothing else teal.
2. **Generate.** `script/illustrations/generate "<scene>" raw.png [1536x1024|1024x1536|1024x1024]`.
   It sends five trap/hug drawings as image references with `script/illustrations/style_prompt.txt`.
   Keep raw PNGs in the scratchpad, not the repo. Generate in parallel when making several.
3. **Check the raw image** before tracing. Regenerate if:
   - the character drifts (curly hair, small head, no cowlick, detailed face)
   - a fill is textured or patterned (it traces as speckle)
   - more than one thing is teal (a teal plant, a teal mug)
   - the scene touches the edges
4. **Trace.** `script/illustrations/trace raw.png app/assets/images/<family>/<name>.svg [WxH]`.
   WxH frames a viewBox of the family's canvas on the drawing's center; leave it off for the full image.
5. **Check the trace.** Render it beside the references, and look at the accent in motion:
   ```sh
   rsvg-convert -h 400 -b white new.svg -o new.png
   rsvg-convert -h 400 -b white app/assets/images/traps/emotional-reasoning.svg -o ref.png
   magick ref.png new.png +append compare.png      # then Read compare.png
   # Accent lifted and hidden: the outline must stay where it is.
   sed 's/<g class="accent">/<g class="accent" transform="translate(0,-40)">/' new.svg > up.svg
   sed 's/<g class="accent">/<g class="accent" opacity="0">/' new.svg > off.svg
   ```
   Zoom into every face (`magick big.png -crop 600x600+X+Y`): check both eyes, the nose and the mouth
   survived the trace (small features can drop out or turn into white specks; `greetings/afternoon.svg`
   lost both eyes this way). Compare a face or hand with the same crop of emotional-reasoning for the
   rough edge.
6. **Install.** Give the image real alt text describing the scene (or `alt: ""` if the text beside it says
   the same thing), the canvas `width`/`height`, and `decoding: "async"`. Run `bin/rails test`.

## Fixing a trace

| Symptom | Fix |
| --- | --- |
| Speckled skin or trousers | The gray sits on the light/mid boundary: retrace with `MID_MAX=165` (or lower) |
| Lines too thin or too heavy | `INK_GROW=0` or `2` (default 1) |
| Rough edge too much / too little | `HALO_SPARSITY` (default 64, higher = fewer), `HALO_REACH` (default 12; must clear the line width) |
| Teal traced as ink, or ink inside the teal missing | Check the raw teal is mid-tone teal; very dark teal reads as ink |
| An eye or other small feature missing | Retrace with `INK_GROW=2`, or add it by hand: an `<ellipse>` (about 9x13 units for a 150-unit head, tilted with the head) inside the `<g fill="#262626">` group, before its transform group |
| White speck in a fill (a stray hole, e.g. beside an eye in `traps/should-statements.svg`) | Find the subpath of that fill's `<path>` whose start lands on the speck (svg x = px × 0.25, y = canvas height − py × 0.25), delete it, and add its `m` offset to the next relative `m` so later subpaths don't shift. Diff the before/after renders: only the speck's pixels should change |
| Texture survives | Regenerate with the scene saying "plain flat fills"; heavier `MEDIAN` blurs the line work |

`script/illustrations/add_halo file.svg...` adds the rough edge to an older traced SVG that lacks it
(as a bottom `class="light"` layer; it skips files that already have one). Restore from git before
re-running it on a file.

## Pitfalls already hit
- `gpt-image-1` is retired; the scripts use `gpt-image-2` (`MODEL=` overrides). It rejects `input_fidelity`.
- Text-only prompts drift from the character. Always generate with the reference images.
- In zsh, `set -- $v` doesn't split words: pass tuning values directly (`HALO_REACH=12 HALO_SPARSITY=64 ...`).
  A value like `Disk:12 64` makes ImageMagick repeat the morphology 64 times and hang.
- Thin ink lines inside the teal vanish if the teal mask is dilated before subtracting it from the ink.
- Skin too dark in an older drawing: the skin shapes share the mid layer with the trousers. Paint each
  `<path>` of the mid layer red in turn to find the face, hand and bare-foot shapes, then move just those
  paths into the light layer (keep the file's `class` attributes for dark mode).
