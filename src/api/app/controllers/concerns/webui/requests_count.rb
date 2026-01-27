module Webui::RequestsCount
  extend ActiveSupport::Concern

  def count_for_request_states
    count = @bs_requests.where(state: params['state']).count
    render partial: 'webui/shared/turbo_counter', locals: { id: "count_#{params['state']}", count: count }
  end

  def count_for_request_types
    count = @bs_requests.where(bs_request_actions: { type: params['type'] }).count
    render partial: 'webui/shared/turbo_counter', locals: { id: "count_#{params['type']}", count: count }
  end
end
