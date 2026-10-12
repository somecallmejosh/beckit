class Situations::RestorationsController < ApplicationController
  # POST /situations/1/restoration
  def create
    situation = Current.user.all_situations.deleted.find(params.expect(:situation_id))
    situation.restore!
    redirect_to situation, notice: "Entry restored.", status: :see_other
  end
end
