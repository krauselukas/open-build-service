class RequestDecisionComponent < ApplicationComponent
  def initialize(bs_request:, package_maintainers:, show_project_maintainer_hint:)
    super

    @bs_request = bs_request
    @package_maintainers = package_maintainers
    @creator = bs_request.creator

    return unless render? && show_project_maintainer_hint

    @package_maintainers_hint = "Note\n" \
                                'You are a project maintainer but not a package maintainer. This package ' \
                                "has #{pluralize(@package_maintainers.size, 'package maintainer')} assigned. Please keep " \
                                'in mind that also package maintainers would like to review this request.'.freeze
  end

  def render?
    policy(@bs_request).handle_request?
  end

  def confirmation
    if @bs_request.state == :review
      { confirm: "Do you really want to approve this request, despite of open review requests?\n\n#{@package_maintainers_hint}" }
    else
      {}
    end
  end

  def other_decision_confirmation(decision_text)
    { confirm: "Do you really want to #{decision_text} this request?\n\n#{@package_maintainers_hint}" }
  end

  def forwards_names
    names = forwards.map { |forward| forward.values.take(2).join('/') }
    names.push("#{forwards.length} more") if forwards.length > 4
    names.to_sentence
  end

  def target_names
    names = submit_actions.first(2).map(&:uniq_key)
    names.push("#{forwards.length} more") if submit_actions.length > 4
    names.to_sentence
  end

  private

  def forwards
    return [] unless submit_actions.any?

    submit_actions.flat_map { |submit_action| submit_action.forward }
  end

  def submit_actions
    @bs_request.bs_request_actions.where(type: :submit)
  end
end
