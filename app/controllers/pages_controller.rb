class PagesController < ApplicationController
  allow_unauthenticated_access

  # GET /
  # Signed-in visitors go straight to their journal; keep any flash set by the redirect that sent them here.
  def home
    if authenticated?
      flash.keep
      redirect_to situations_path
    else
      @distortions = Distortion.order(:title)
      @sample_insights = SampleInsights.new
    end
  end

  # GET /privacy
  def privacy
  end
end
