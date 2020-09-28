module Webui::NotificationHelper
  def link_to_all
    parameters = params.slice(:show_all, :type, :project).permit!
    all_or_less = parameters[:show_all] ? 'less' : 'all'
    parameters[:show_all] = parameters[:show_all] ? nil : '1'
    link_to("Show #{all_or_less}", my_notifications_path(parameters))
  end

  def filter_notification_link(link_text, amount, filter_item, selected_filter)
    link_to(my_notifications_path(filter_item), class: css_for_filter_link(filter_item, selected_filter)) do
      concat(link_text)
      concat(tag.span(amount, class: "badge #{badge_color(filter_item, selected_filter)} align-text-top ml-2")) if amount && amount.positive?
    end
  end

  def request_badge_color(state)
    case state
    when :review, :new
      'secondary'
    when :declined, :revoke
      'danger'
    when :superseded
      'warning'
    when :accepted
      'success'
    else
      'dark'
    end
  end

  private

  def css_for_filter_link(filter_item, selected_filter)
    css_class = 'list-group-item list-group-item-action'
    css_class += ' active' if notification_filter_matches(filter_item, selected_filter)
    css_class
  end

  def notification_filter_matches(filter_item, selected_filter)
    if selected_filter[:project].present?
      filter_item[:project] == selected_filter[:project]
    elsif selected_filter[:type].present?
      filter_item[:type] == selected_filter[:type]
    else
      filter_item[:type] == 'unread'
    end
  end

  def badge_color(filter_item, selected_filter)
    notification_filter_matches(filter_item, selected_filter) ? 'badge-light' : 'badge-primary'
  end
end
