class PagesController < ApplicationController
  allow_unauthenticated_access

  # GET /
  # Signed-in visitors go straight to their journal; keep any flash set by the redirect that sent them here.
  def home
    if authenticated?
      flash.keep
      redirect_to situations_path
    else
      @distortions = Distortion.includes(image_attachment: { blob: { variant_records: { image_attachment: :blob } } }).order(:title)
      @sample_insights = SampleInsights.new
    end
  end

  # GET /privacy
  def privacy
  end

  # GET /disclaimer
  def disclaimer
  end
end
