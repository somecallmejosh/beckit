class InsightsController < ApplicationController
  # GET /insights
  def show
    distortion = Distortion.find_by(id: params[:distortion_id]) if params[:distortion_id].present?
    @insights = DistortionInsights.new(Current.user, range: params[:range], distortion:)
  end
end
