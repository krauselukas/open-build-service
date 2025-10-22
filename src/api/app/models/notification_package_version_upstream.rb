class NotificationPackageVersionUpstream < Notification
  def description
    if event_payload['develpackage'].present?
      "The latest upstream version for #{event_payload['project']}/#{event_payload['package']}
       developed in #{event_payload['develproject']}/#{event_payload['develpackage']} has changed to: #{event_payload['upstream_version']}"
    else
      "The latest upstream version for #{event_payload['project']}/#{event_payload['package']} has changed to: #{event_payload['upstream_version']}"
    end
  end

  def link_path
    Rails.application.routes.url_helpers.package_show_path(package: event_payload['package'], project: event_payload['project'],
                                                           notification_id: id)
  end

  def link_text
    "Version changed in upstream project for #{event_payload['project']}/#{event_payload['package']}"
  end

  def avatar_objects
    if event_payload['develpackage'].present?
      maintainers = Package.find_by_project_and_name(event_payload['develproject'], event_payload['develpackage']).maintainers
      return maintainers unless maintainers.blank?

      Project.find_by_name(event_payload['develproject']).maintainers
    else
      maintainers = Package.find_by_project_and_name(event_payload['project'], event_payload['package']).maintainers
      return maintainers unless maintainers.blank?

      Project.find_by_name(event_payload['project']).maintainers
    end
  end

  def excerpt
    ''
  end
end
