module DistortionsHelper
  # The trap's animated drawing while it still has its starter image, otherwise the image at page size.
  def distortion_image_source(distortion)
    distortion.illustration || distortion.image.variant(:page)
  end
end
