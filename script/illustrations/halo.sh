# Sourced by trace and add_halo. The beckit rough edge: here and there a gray fill slips a few pixels
# past its outline, as in traps/emotional-reasoning.svg. Subtle: thin slivers, never around white shapes.
#
# make_halo fills.png painted.png keepout.png out.png
#   fills    white where a gray fill is (the halo grows out of these)
#   painted  white where anything is drawn, ink included (the halo only lands on white paper)
#   keepout  white where no halo may go (the floating accent)
make_halo () {
  local w h
  w=$(magick identify -format %w "$1"); h=$(magick identify -format %h "$1")
  magick -size "${w}x${h}" xc: -seed "${SEED:-7}" +noise Random -channel G -separate +channel \
    -blur 0x18 -normalize -threshold "${HALO_SPARSITY:-64}%" "$4.patches.png"
  magick "$1" -morphology Dilate "Disk:${HALO_REACH:-12}" \
    "$2" -compose MinusSrc -composite \
    "$3" -compose MinusSrc -composite \
    "$4.patches.png" -compose Multiply -composite \
    -morphology Open Disk:2 "$4"
  rm "$4.patches.png"
}

# potrace_paths mask.png -> <path> elements, in the 0.25 scale every beckit drawing uses
potrace_paths () {
  magick "$1" -negate "$1.pbm"
  potrace -s -u 4 -t 4 -a 1.1 -O 0.4 --flat -o "$1.svg" "$1.pbm"
  tr '\n' ' ' < "$1.svg" | grep -o '<path d="[^"]*"/>' | tr -s ' '
}
