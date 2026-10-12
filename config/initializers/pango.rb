# Social cards (Distortion::OgCard) load their fonts from lib/og/fonts through fontconfig. On macOS, Pango
# otherwise draws with CoreText and ignores those files; Linux already uses fontconfig, so this is a no-op there.
ENV["PANGOCAIRO_BACKEND"] ||= "fc"
