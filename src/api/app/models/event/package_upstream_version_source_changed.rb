module Event
  class PackageUpstreamVersionSourceChanged < Base
    self.description = 'Version of the upstream package source has changed'
    self.message_bus_routing_key = 'package.upstream_version_source_changed'
    self.notification_explanation = 'Receive notifications when the version of the upstream source of a package has changed'
    payload_keys :local_version, :upstream_version, :project, :package, :package_version_upstream_id, :develpackage, :develproject
    receiver_roles :maintainer, :devel_package_maintainer

    #after_create :create_event_for_devel_package

    def parameters_for_notification
      super.merge(notifiable_type: 'PackageVersionUpstream', type: 'NotificationPackageVersionUpstream', notifiable_id: payload['package_version_upstream_id'])
    end

    private

    # we send out notifications to the maintainers of the devel package incase there is one,
    # otherwise to the direct package maintainers
    # def create_event_for_devel_package
    #   package = Package.find_by_project_and_name(payload['project'], payload['package'])
    #   develpackage = package.develpackage

    #   return if develpackage.blank?

    #   Event::PackageUpstreamVersionSourceChanged.create(local_version: payload['local_version'], upstream_version: payload['upstream_version'],
    #                                                     package: develpackage.name, project: develpackage.project.name, package_version_upstream_id: payload['package_version_upstream_id'])

    #   # since there is a develpackage associated, we mark this event as sent to only send notifications to the devel package maintainers
    #   #self.update(mails_sent: true)
    # end
  end
end
