# rubocop:disable Metrics/ClassLength
class NotificationNotifiableLinkComponent < ApplicationComponent
  def initialize(notification)
    super

    @notification = notification
  end

  def call
    case @notification.event_type
    when 'Event::ReportForProject', 'Event::ReportForPackage', 'Event::ReportForComment', 'Event::ReportForUser'
      link_to(notifiable_link_text, link_to_reportables(notification_id: @notification.id, event_payload: @notification.event_payload,
                                                        event_type: @notification.event_type), class: 'mx-1')
    else
      link_to(notifiable_link_text, notifiable_link_path, class: 'mx-1')
    end
  end

  private

  # rubocop:disable Metrics/CyclomaticComplexity
  def notifiable_link_text
    case @notification.event_type
    when 'Event::RequestStatechange', 'Event::RequestCreate', 'Event::ReviewWanted'
      "#{helpers.request_type_of_action(@notification.notifiable)} Request ##{@notification.notifiable.number}"
    when 'Event::CommentForRequest'
      "Comment on #{helpers.request_type_of_action(bs_request)} Request ##{bs_request.number}"
    when 'Event::CommentForProject'
      'Comment on Project'
    when 'Event::CommentForPackage'
      'Comment on Package'
    when 'Event::RelationshipCreate'
      role = @notification.event_payload['role']
      if @notification.event_payload['package']
        "Added as #{role} of a package"
      else
        "Added as #{role} of a project"
      end
    when 'Event::RelationshipDelete'
      role = @notification.event_payload['role']
      if @notification.event_payload['package']
        "Removed as #{role} of a package"
      else
        "Removed as #{role} of a project"
      end
    when 'Event::BuildFail'
      project = @notification.event_payload['project']
      package = @notification.event_payload['package']
      repository = @notification.event_payload['repository']
      arch = @notification.event_payload['arch']
      "Package #{package} on #{project} project failed to build against #{repository} / #{arch}"
    when 'Event::ReportForProject', 'Event::ReportForPackage', 'Event::ReportForComment', 'Event::ReportForUser'
      "Report for a #{@notification.event_payload['reportable_type']}"
    when 'Event::ClearedDecision'
      # All reports should point to the same reportable. We will take care of that here:
      # https://trello.com/c/xrjOZGa7/45-ensure-all-reports-of-a-decision-point-to-the-same-reportable
      report = @notification.notifiable.reports.first
      "Cleared #{report.reportable.class.name} Report"
    when 'Event::FavoredDecision'
      # All reports should point to the same reportable. We will take care of that here:
      # https://trello.com/c/xrjOZGa7/45-ensure-all-reports-of-a-decision-point-to-the-same-reportable
      report = @notification.notifiable.reports.first
      "Favored #{report.reportable.class.name} Report"
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  # rubocop:disable Metrics/CyclomaticComplexity
  def notifiable_link_path
    case @notification.event_type
    when 'Event::RequestStatechange', 'Event::RequestCreate', 'Event::ReviewWanted'
      Rails.application.routes.url_helpers.request_show_path(@notification.notifiable.number, notification_id: @notification.id)
    when 'Event::CommentForRequest'
      # TODO: It would be better to eager load the commentable association with `includes(...)`,
      #      but it's complicated since this isn't for all notifications and it's nested 2 levels deep.
      anchor = if @notification.notifiable.commentable.is_a?(BsRequestAction)
                 'tab-pane-changes'
               else
                 'comments-list'
               end
      Rails.application.routes.url_helpers.request_show_path(bs_request.number, notification_id: @notification.id, anchor: anchor)
    when 'Event::CommentForProject'
      Rails.application.routes.url_helpers.project_show_path(@notification.notifiable.commentable, notification_id: @notification.id, anchor: 'comments-list')
    when 'Event::CommentForPackage'
      # TODO: It would be better to eager load the commentable association with `includes(...)`,
      #       but it's complicated since this isn't for all notifications and it's nested 2 levels deep.
      package = @notification.notifiable.commentable
      Rails.application.routes.url_helpers.package_show_path(package: package,
                                                             project: package.project,
                                                             notification_id: @notification.id,
                                                             anchor: 'comments-list')
    when 'Event::RelationshipCreate', 'Event::RelationshipDelete'
      if @notification.event_payload['package']
        Rails.application.routes.url_helpers.package_users_path(@notification.event_payload['project'],
                                                                @notification.event_payload['package'])
      else
        Rails.application.routes.url_helpers.project_users_path(@notification.event_payload['project'])
      end
    when 'Event::BuildFail'
      Rails.application.routes.url_helpers.package_live_build_log_path(package: @notification.event_payload['package'], project: @notification.event_payload['project'],
                                                                       repository: @notification.event_payload['repository'], arch: @notification.event_payload['arch'])
    when 'Event::ClearedDecision', 'Event::FavoredDecision'
      #reportable = @notification.notifiable.reports.first.reportable
      #link_for_reportables(reportable)
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def bs_request
    return unless @notification.event_type == 'Event::CommentForRequest'

    if @notification.notifiable.commentable.is_a?(BsRequestAction)
      @notification.notifiable.commentable.bs_request
    else
      @notification.notifiable.commentable
    end
  end

  def link_to_reportables(notification_id:, event_payload:, event_type:)
    case event_type
    when 'Event::ReportForPackage'
      Rails.application.routes.url_helpers.package_show_path(package: event_payload['package_name'] ,
                                                             project: event_payload['project_name'],
                                                             notification_id: notification_id,
                                                             anchor: 'comments-list')
    when 'Event::ReportForProject'
      Rails.application.routes.url_helpers.project_show_path(event_payload['project_name'], notification_id: notification_id, anchor: 'comments-list')
    when 'Event::ReportForUser'
      Rails.application.routes.url_helpers.user_path(event_payload['user_login'])
    when 'Event::ReportForComment'
      link_to_commentables_on_reports(notification_id: notification_id, event_payload: event_payload)
    end
  end

  def link_to_commentables_on_reports(notification_id:, event_payload:)
    case event_payload['commentable_type']
    when 'BsRequest'
      Rails.application.routes.url_helpers.request_show_path(event_payload['bs_request_number'],
                                                             notification_id: notification_id, anchor: 'comments-list')
    when 'BsRequestAction'
      Rails.application.routes.url_helpers.request_show_path(number: event_payload['bs_request_number'],
                                                             request_action_id: event_payload['bs_request_action_id'],
                                                             notification_id: notification_id, anchor: 'tab-pane-changes')
    when 'Package'
      Rails.application.routes.url_helpers.package_show_path(package: event_payload['package_name'],
                                                             project: event_payload['project_name'],
                                                             notification_id: notification_id,
                                                             anchor: 'comments-list')
    when 'Project'
      Rails.application.routes.url_helpers.project_show_path(event_payload['project_name'], notification_id: notification_id, anchor: 'comments-list')
    end
  end
end
# rubocop:enable Metrics/ClassLength
