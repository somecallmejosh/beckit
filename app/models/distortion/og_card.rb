# The 1200x630 social card for a thinking trap: wordmark, "Thinking trap", title and description on the left,
# the trap's photo on the right. Same layout as public/og-image.png. Drawn with libvips so it can be built on
# the server whenever an admin changes the photo or text (no browser needed).
class Distortion::OgCard
  WIDTH, HEIGHT = 1200, 630
  PAD = 64
  PHOTO_W, PHOTO_H, PHOTO_RADIUS = 400, 502, 28
  TEXT_X = PAD + 16
  TEXT_W = WIDTH - PAD * 2 - PHOTO_W - 64 - 16

  ASSETS = Rails.root.join("lib/og")
  INK, MUTED, TEAL = "#1c1917", "#57534d", "#00786f"
  TOP, BOTTOM = [ 239, 252, 249 ], [ 250, 250, 249 ] # teal-50 fading to stone-50, like the landing card

  def initialize(distortion)
    @distortion = distortion
  end

  def to_png
    layers = [ logo, photo ]
    xs, ys = [ TEXT_X, WIDTH - PAD - PHOTO_W ], [ 70, PAD ]

    # The text block sits on the bottom edge of the photo, stacked upward.
    bottom = PAD + PHOTO_H
    [ [ description, 24 ], [ title, 12 ], [ label, 0 ] ].each do |layer, gap_above|
      bottom -= layer.height
      layers << layer
      xs << TEXT_X
      ys << bottom
      bottom -= gap_above
    end

    background.composite(layers, :over, x: xs, y: ys).extract_band(0, n: 3).write_to_buffer(".png")
  end

  private
    def background
      t = (Vips::Image.xyz(WIDTH, HEIGHT)[1] / (HEIGHT * 0.55)).then { |v| (v > 1).ifthenelse(1, v) }
      TOP.zip(BOTTOM).map { |top, bottom| t * (bottom - top) + top }.reduce(:bandjoin).cast(:uchar).copy(interpretation: :srgb)
    end

    def logo
      Vips::Image.new_from_file(ASSETS.join("logo.png").to_s).colourspace(:srgb).then { ensure_alpha(it) }.resize(36.0 / 64)
    end

    def photo
      @distortion.image.blob.open do |file|
        image = Vips::Image.thumbnail(file.path, PHOTO_W, height: PHOTO_H, crop: :centre).colourspace(:srgb)
        image = image.flatten if image.has_alpha?
        image.bandjoin(rounded_mask(image.width, image.height))
      end
    end

    # Alpha mask for a rounded rectangle, anti-aliased over one pixel.
    def rounded_mask(width, height)
      xy = Vips::Image.xyz(width, height)
      dx = distance_outside_corner(xy[0], width)
      dy = distance_outside_corner(xy[1], height)
      alpha = ((dx * dx + dy * dy) ** 0.5) * -1 + (PHOTO_RADIUS + 0.5)
      ((alpha > 1).ifthenelse(1, alpha) * 255).then { |a| (a < 0).ifthenelse(0, a) }.cast(:uchar)
    end

    def distance_outside_corner(coord, size)
      inner = (coord * -1 + PHOTO_RADIUS).maxpair(coord - (size - 1 - PHOTO_RADIUS))
      (inner < 0).ifthenelse(0, inner)
    end

    def label = text("Thinking trap", font: "OG Inter Medium 24", file: "Inter-Medium.ttf", color: TEAL)

    def title
      text(@distortion.title, font: "OG Lora 76", file: "Lora-Medium.ttf", color: INK, line_height: 0.82, letter_spacing: -0.02 * 76)
    end

    # Typographic quotes and apostrophes; the stored descriptions use straight ones.
    def description
      words = @distortion.description.gsub(/"([^"]*)"/, "“\\1”").tr("'", "’")
      text(words, font: "OG Inter 24", file: "Inter-Regular.ttf", color: MUTED, line_height: 1.15)
    end

    # Pango line_height is a multiple of the font's own line height (about 1.25em), not of the font size.
    def text(string, font:, file:, color:, line_height: 1, letter_spacing: 0)
      markup = %(<span foreground="#{color}" line_height="#{line_height}" letter_spacing="#{(letter_spacing * 1024).round}">#{ERB::Util.h(string)}</span>)
      Vips::Image.text(markup, font:, fontfile: ASSETS.join("fonts", file).to_s, width: TEXT_W, dpi: 72, rgba: true, wrap: :word)
    end

    def ensure_alpha(image) = image.has_alpha? ? image : image.bandjoin(255)
end
