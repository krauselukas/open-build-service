module Event
  class PackageUpstreamVersionSourceChanged < Base
    self.description = 'Version of the upstream package source has changed'
    self.message_bus_routing_key = 'package.upstream_version_source_changed'
    self.notification_explanation = 'Receive notifications when the version of the upstream source of a package has changed'
    payload_keys :local_version, :upstream_version, :project, :package, :package_version_upstream_id, :develpackage, :develproject
    receiver_roles :maintainer, :devel_package_maintainer

    def parameters_for_notification
      super.merge(notifiable_type: 'PackageVersionUpstream', type: 'NotificationPackageVersionUpstream', notifiable_id: payload['package_version_upstream_id'])
    end
  end
end
