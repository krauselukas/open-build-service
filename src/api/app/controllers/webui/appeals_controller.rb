class Webui::AppealsController < Webui::WebuiController
  after_action :verify_authorized

  def new
    @decision = Decision.find(params[:decision_id])
    @appeal = Appeal.new(decision: @decision)

    authorize @appeal
  end

  def show
    @appeal = Appeal.find(params[:id])

    authorize @appeal
  end

  def create
    @decision = Decision.find(decision_params)
    @appeal = Appeal.new(appeal_params)
    @appeal.decision = @decision
    @appeal.appellant = User.session!

    authorize @appeal

    if @appeal.save
      flash[:success] = "Appeal created successfully!"
      redirect_to @appeal
    else
      flash[:error] = @appeal.errors.full_messages.to_sentence
      render "new"
    end
  end

  private

  def decision_params
    params.require(:decision_id)
  end

  def appeal_params
    params.require(:appeal).permit(:reason)
  end
end
