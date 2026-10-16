class SituationsController < ApplicationController
  include SituationSteps

  PER_PAGE = 20

  before_action :set_situation, only: %i[ show destroy ]
  before_action :set_distortions, :set_suggestions, only: %i[ new create ]

  # GET /situations
  # GET /situations?q=&distortion_id=&insights_range=&page= ; GET /situations.csv exports every entry (linked from Settings).
  def index
    situations = Current.user.situations.includes(:distortions).order(date: :desc)

    respond_to do |format|
      format.html do
        @summary = DistortionInsights.new(Current.user, range: "30")
        @any_entries = Current.user.situations.exists?
        filter_and_paginate(situations)
      end
      format.csv { send_data situations.to_csv, filename: "beckit-entries-#{Date.current.iso8601}.csv", type: :csv }
    end
  end

  # GET /situations/1
  def show
  end

  # GET /situations/new ; the first step. The date is on the second, so it starts as now.
  def new
    @situation = Current.user.situations.build(date: Time.current.change(sec: 0))
  end

  # POST /situations ; saves the first step, then goes where its button says (see SituationSteps).
  def create
    @situation = Current.user.situations.build(date: Time.current.change(sec: 0))

    if @situation.save_step(Situation::STEPS.first, situation_params)
      redirect_after_step @situation
    else
      render :new, status: :unprocessable_content
    end
  end

  # DELETE /situations/1
  # Hidden rather than removed, so the flash can offer Undo; PurgeDeletedSituationsJob removes it later.
  def destroy
    @situation.trash!
    flash[:undo_situation_id] = @situation.id
    redirect_to situations_path, notice: "Entry deleted.", status: :see_other
  end

  private
    # One extra row tells us whether there is an older page, without a count query.
    def filter_and_paginate(situations)
      @query = params[:q].to_s.squish
      @distortion = Distortion.find_by(id: params[:distortion_id]) if params[:distortion_id].present?
      # Set when a thinking trap's Insights page linked here, so the journal can link back to the same view.
      @insights_range = params[:insights_range] if @distortion && DistortionInsights::RANGES.key?(params[:insights_range])
      situations = situations.search(@query) if @query.present?
      situations = situations.tagged_with(@distortion) if @distortion
      @match_count = situations.count if @query.present? || @distortion

      @page = [ params[:page].to_i, 1 ].max
      @page_count = [ ((@match_count || situations.count) / PER_PAGE.to_f).ceil, 1 ].max
      @older_page = @page < @page_count
      offset = (@page - 1) * PER_PAGE
      @situations = situations.offset(offset).limit(PER_PAGE).to_a
      # The month at the top of a later page may have started on the page before; its heading says so.
      if @page > 1 && (first = @situations.first)
        @continued_month = first.date.beginning_of_month if situations.offset(offset - 1).limit(1).pick(:date)&.beginning_of_month == first.date.beginning_of_month
      end
    end

    # Scoped to the current user so other users' situations are not reachable.
    def set_situation
      @situation = Current.user.situations.find(params.expect(:id))
    end
end
