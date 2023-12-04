class Webui::AppealsController < Webui::WebuiController
  def new
    @decision = Decision.find(params[:decision_id])
    @appeal = Appeal.new(decision: @decision)
  end

  def show
    @decision = Decision.find(show_params[:decision_id])
    @appeal = Appeal.find(show_params[:id])
  end

  def create
    @decision = Decision.find(decision_params)
    @appeal = Appeal.new(appeal_params)
    @appeal.decision = @decision
    @appeal.appellant = User.session!

    if @appeal.save
      flash[:success] = "Appeal created successfully!"
      redirect_to [@decision, @appeal]
    else
      flash[:error] = @appeal.errors.full_messages.to_sentence
      render "new"
    end
  end

  private

  def show_params
    params.permit(:decision_id, :id)
  end

  def decision_params
    params.require(:decision_id)
  end

  def appeal_params
    params.require(:appeal).permit(:reason)
  end
end
