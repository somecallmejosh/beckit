class Distortion::RefreshOgImageJob < ApplicationJob
  queue_as :default

  def perform(distortion)
    distortion.refresh_og_image
  end
end
