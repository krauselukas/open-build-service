class NotificationComponent < ApplicationComponent
  def initialize(notification:, selected_filter:, page:, show_more:)
    super

    @notification = notification
    @selected_filter = selected_filter
    @page = page
    @show_more = show_more
  end

  def notification_icon
    case @notification.notifiable_type
    when 'BsRequest'
      tag.i(class: ['fas', 'fa-code-pull-request'], title: 'Request notification')
    when 'Comment'
      tag.i(class: ['fas', 'fa-comments'], title: 'Comment notification')
    when 'Package'
      tag.i(class: ['fas', helpers.build_status_icon(:failed)], title: 'Package notification')
    when 'Report'
      tag.i(class: ['fas', 'fa-flag'], title: 'Report notification')
    when 'Decision'
      tag.i(class: ['fas', 'fa-clipboard-check'], title: 'Report decision')
    when 'Appeal'
      tag.i(class: ['fas', 'fa-flag'], title: 'Decision appeal')
    when 'WorkflowRun'
      tag.i(class: ['fas', 'fa-book-open'], title: 'Workflow run')
    else
      tag.i(class: ['fas', 'fa-user-tag'], title: 'Relationship notification')
    end
  end
end
