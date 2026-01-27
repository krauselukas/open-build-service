module Webui::RequestsCount
  extend ActiveSupport::Concern

  FILTERABLE_BSREQUEST_TYPES = %w[set_bugowner change_devel delete maintenance_incident
                                  maintenance_release release add_role submit].freeze

  def counts_for_states_and_types
    @counts_grouped_by_state = @bs_requests.group(:state).order(:state).count
    @counts_grouped_by_state = BsRequest::VALID_REQUEST_STATES.map(&:to_s).index_with { |k| @counts_grouped_by_state.fetch(k, 0) }

    @counts_grouped_by_type = @bs_requests.group(:type).order(:type).count
    @counts_grouped_by_type = FILTERABLE_BSREQUEST_TYPES.index_with { |k| @counts_grouped_by_type.fetch(k, 0) }

    respond_to do |format|
      format.turbo_stream
    end
  end
end
