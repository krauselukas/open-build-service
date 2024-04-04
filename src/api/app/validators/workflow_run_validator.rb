class WorkflowRunValidator < ActiveModel::Validator
  ALLOWED_PULL_REQUEST_ACTIONS = %w[closed opened reopened synchronize synchronized].freeze
  ALLOWED_MERGE_REQUEST_ACTIONS = %w[close merge open reopen update].freeze

  def validate(record)
    @workflow_run = record

    @workflow_run.errors.add(:hook_action, ignored_event_message) if ignored_pull_request_action?
  end

  private

  def ignored_pull_request_action?
    ignored_github_pull_request_action? || ignored_gitlab_merge_request_action? || ignored_gitea_pull_request_action?
  end

  def ignored_github_pull_request_action?
    github_pull_request? && ALLOWED_PULL_REQUEST_ACTIONS.exclude?(@workflow_run.hook_action)
  end

  def github_pull_request?
    @workflow_run.scm_vendor == 'github' && @workflow_run.hook_event == 'pull_request'
  end

  def ignored_gitlab_merge_request_action?
    gitlab_merge_request? && ALLOWED_MERGE_REQUEST_ACTIONS.exclude?(@workflow_run.hook_action)
  end

  def gitlab_merge_request?
    @workflow_run.scm_vendor == 'gitlab' && @workflow_run.hook_event == 'Merge Request Hook'
  end

  def ignored_gitea_pull_request_action?
    gitea_pull_request? && ALLOWED_PULL_REQUEST_ACTIONS.exclude?(@workflow_run.hook_action)
  end

  def gitea_pull_request?
    @workflow_run.scm_vendor == 'gitea' && @workflow_run.hook_event == 'pull_request'
  end

  def ignored_event_message
    action = @workflow_run.hook_action

    info_msg = "Events '#{@workflow_run.hook_event}' "
    info_msg += "and actions '#{action}' " if action.present?
    info_msg += 'are unsupported'
  end
end
