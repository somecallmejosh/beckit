class Situations::StepsController < ApplicationController
  include SituationSteps

  before_action :set_situation, :set_step, :set_distortions, :set_suggestions
  before_action :keep_within_reach, only: :show

  # GET /situations/1/steps/what-happened
  def show
  end

  # PATCH /situations/1/steps/what-happened
  def update
    if @situation.save_step(@step, situation_params)
      redirect_after_step @situation
    else
      render :show, status: :unprocessable_content
    end
  end

  private
    # Scoped to the current user so other users' situations are not reachable.
    def set_situation
      @situation = Current.user.situations.find(params.expect(:situation_id))
    end

    def set_step
      @step = params[:id]
      raise ActiveRecord::RecordNotFound unless @step.in?(Situation::STEPS)
    end

    # A step past the first unanswered one (a typed URL, or Next on an older step) opens that one instead.
    def keep_within_reach
      redirect_to situation_step_path(@situation, @situation.next_step) unless @situation.reachable?(@step)
    end
end
