class DistortionsController < ApplicationController
  require_admin except: %i[ index show ]
  before_action :set_distortion, only: %i[ show edit update destroy ]

  # GET /distortions
  def index
    @distortions = Distortion.order(:title)
  end

  # GET /distortions/1
  def show
    entries = Current.user.situations.joins(:situation_distortions).where(situation_distortions: { distortion_id: @distortion.id })
    @entry_count = entries.count
    @recent_entries = entries.order(date: :desc).limit(5)
  end

  # GET /distortions/new
  def new
    @distortion = Distortion.new
  end

  # GET /distortions/1/edit
  def edit
  end

  # POST /distortions
  def create
    @distortion = Distortion.new(distortion_params)

    if @distortion.save
      redirect_to @distortion, notice: "Distortion was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /distortions/1
  def update
    if @distortion.update(distortion_params)
      redirect_to @distortion, notice: "Distortion was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /distortions/1
  def destroy
    @distortion.destroy!
    redirect_to distortions_path, notice: "Distortion was successfully destroyed.", status: :see_other
  end

  private
    def set_distortion
      @distortion = Distortion.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def distortion_params
      params.expect(distortion: [ :title, :description ])
    end
end
