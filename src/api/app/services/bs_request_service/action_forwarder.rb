module BsRequestService
  class ActionForwarder

    def initialize(bs_request)
      @bs_request = bs_request
      @bs_request_actions = bs_request.bs_request_actions
    end

    def forwardable_actions_exist?
      true unless @bs_request_actions.any? { |action| forwardable_exist?(action) }
    end

    def forward_actions_in_single_request(fwd_targets)
      new_request = BsRequest.new
      BsRequest.transaction do
        fwd_targets.each do |target|
          new_request.bs_request_actions << create_forwarding_action(target_id, target_project, target_package)
        end
        new_request.save!
      end
    end

    private

    def create_forwarding_action(bs_request_action_id, target_project, target_package)
      previous_action = @bs_request_actions.where(id: bs_request_action_id)
      rev = Directory.hashed(project: action.target_project, package: action.target_package)['rev']

      BsRequestAction.new(source_project: previous_action.target_project,
                          source_package: previous_action.target_package,
                          source_rev: rev,
                          target_project: target_project,
                          target_package: target_package,
                          type: previous_action.type)
    end

    def forwarding_targets(bs_request_action)
      target_package = bs_request_action.target_package_object
      forwarding_targets = target_package.developed_packages
      linkinfo = target_package.linkinfo
      return forwarding_targets unless bs_request_action.linkinfo

      unless forwarding_targets.any? { |t| t.name == linkinfo['package'] && t.project.name == linkinfo['project'] }
        forwarding_targets.append(Package.find_by_project_and_name(linkinfo['project'], linkinfo['package']))
      end

      forwarding_targets
    end

    def forwardable_exist?(bs_request_action)
      return false unless bs_request_action.type == 'submit'
      return false if bs_request_action.target_package_object.nil?
      return false unless bs_request_action.target_package_object.developed_packages.any? || bs_request_action.target_package_object.linkinfo
      true
    end
  end
end
