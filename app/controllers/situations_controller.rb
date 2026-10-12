class SituationsController < ApplicationController
  WHO_PRESETS = %w[ Self Colleague Spouse Daughter Son Parent Friend ].freeze
  PER_PAGE = 20

  before_action :set_situation, only: %i[ show edit update destroy ]
  before_action :set_distortions, :set_suggestions, only: %i[ new edit create update ]

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

  # GET /situations/new
  def new
    @situation = Current.user.situations.build(date: Time.current.change(sec: 0))
  end

  # GET /situations/1/edit
  def edit
  end

  # POST /situations
  def create
    @situation = Current.user.situations.build(situation_params)

    if @situation.save
      redirect_to @situation, notice: "Entry saved."
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /situations/1
  def update
    if @situation.update(situation_params)
      redirect_to @situation, notice: "Entry updated.", status: :see_other
    else
      render :edit, status: :unprocessable_content
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
      records = situations.offset((@page - 1) * PER_PAGE).limit(PER_PAGE + 1).to_a
      @older_page = records.size > PER_PAGE
      @situations = records.first(PER_PAGE)
    end

    # Scoped to the current user so other users' situations are not reachable.
    def set_situation
      @situation = Current.user.situations.find(params.expect(:id))
    end

    # The user's most-used thinking traps first, then alphabetical.
    def set_distortions
      usage = Current.user.situations.joins(:situation_distortions).group("situation_distortions.distortion_id").count
      @distortions = Distortion.order(:title).sort_by { [ -usage.fetch(it.id, 0), it.title ] }
      @distortions_used = usage.any?
    end

    # Past answers (most used first) offered as datalist suggestions.
    def set_suggestions
      @location_options = past_values(:location)
      @who_options = (WHO_PRESETS + past_values(:who_was_involved)).uniq(&:downcase)
    end

    def past_values(column)
      Current.user.situations.where.not(column => nil).group(column).order(Arel.sql("COUNT(*) DESC"), column).pluck(column)
    end

    # Only allow a list of trusted parameters through. user_id is set from Current.user.
    def situation_params
      params.expect(situation: [ :title, :date, :location, :distortion_id, :who_was_involved, :thought_imagery, :emotion_level, :emotion_level_after,
        :evidence_for, :evidence_against, :balanced_thought, distortion_ids: [], emotions: [] ])
    end
end
