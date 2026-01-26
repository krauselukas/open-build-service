module Webui
  module Projects
    class BsRequestsController < WebuiController
      include Webui::RequestsFilter

      before_action :set_project
      before_action :set_bs_requests

      def index
        if Flipper.enabled?(:request_index, User.session)
          # FIXME: Once we roll out filter_requests should become a before_action
          filter_requests
          @bs_requests = @bs_requests.order(number: :desc).page(params[:page])
        # TODO: Remove this else block once request_index beta is rolled out
        else
          if request.format.json?
            parsed_params = BsRequest::DataTable::ParamsParserWithStateAndType.new(params).parsed_params
            requests_query = BsRequest::DataTable::FindForProjectQuery.new(@project, parsed_params)
            @requests_data_table = BsRequest::DataTable::Table.new(requests_query, params[:draw])
          else
            @default_request_type = params[:type] if params[:type]
            @default_request_state = params[:state] if params[:state]
          end

          respond_to do |format|
            format.json { render 'webui/shared/bs_requests/index' }
            format.html { render 'webui/project/requests' }
          end
        end
      end

      private

      def set_bs_requests
        return unless Flipper.enabled?(:request_index, User.session)

        @bs_requests = @project.bs_requests
      end

      def filter_involvement
        @selected_filter['involvement'] = params[:involvement] if params[:involvement]&.compact_blank.present?
        bs_requests_filters = []

        bs_requests_filters << @bs_requests.where(bs_request_actions: { target_project_id: @project.id }) if @selected_filter['involvement'].include?('incoming')

        bs_requests_filters << @bs_requests.where(bs_request_actions: { source_project_id: @project.id }) if @selected_filter['involvement'].include?('outgoing')

        bs_requests_filters << @bs_requests.where(reviews: { project_id: @project.id }) if @selected_filter['involvement'].include?('review')

        @bs_requests = @bs_requests.merge(bs_requests_filters.inject(:or)) if bs_requests_filters.length.positive?
      end
    end
  end
end
