class SituationsController < ApplicationController
  WHO_PRESETS = %w[ Self Colleague Spouse Daughter Son Parent Friend ].freeze

  before_action :set_situation, only: %i[ show edit update destroy ]
  before_action :set_distortions, :set_suggestions, only: %i[ new edit create update ]

  # GET /situations
  # GET /situations.csv exports every entry (linked from Settings).
  def index
    @situations = Current.user.situations.includes(:distortions).order(date: :desc)

    respond_to do |format|
      format.html { @summary = DistortionInsights.new(Current.user, range: "30") }
      format.csv { send_data @situations.to_csv, filename: "beckit-entries-#{Date.current.iso8601}.csv", type: :csv }
    end
  end

  # GET /situations/1
  def show
  end

  # GET /situations/new
  def new
    @situation = Current.user.situations.build(date: Time.current)
  end

  # GET /situations/1/edit
  def edit
  end

  # POST /situations
  def create
    @situation = Current.user.situations.build(situation_params)

    if @situation.save
      redirect_to @situation, notice: "Situation was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /situations/1
  def update
    if @situation.update(situation_params)
      redirect_to @situation, notice: "Situation was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /situations/1
  def destroy
    @situation.destroy!
    redirect_to situations_path, notice: "Situation was successfully destroyed.", status: :see_other
  end

  private
    # Scoped to the current user so other users' situations are not reachable.
    def set_situation
      @situation = Current.user.situations.find(params.expect(:id))
    end

    def set_distortions
      @distortions = Distortion.order(:title)
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
      params.expect(situation: [ :title, :date, :location, :distortion_id, :who_was_involved, :thought_imagery, :emotion_level, :evidence_for, :evidence_against, :balanced_thought, distortion_ids: [] ])
    end
end
