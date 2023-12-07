class DecisionPolicy < ApplicationPolicy
  def create?
    return false unless Flipper.enabled?(:content_moderation, user)

    user.is_moderator? || user.is_admin? || user.is_staff?
  end

  def appeal?
    return false if record.kind? == 'cleared'

    report = record.reports.first

    case report.reportable_type
    when 'User'
      return false unless report.reportable == user
    when 'Comment'
      return false unless report.reportable.user == user
    when 'Package'
      return false unless PackagePolicy.new(user, report.reportable).update?
    when 'Project'
      return false unless ProjectPolicy.new(user, record.reportable).update?
    end

    true
  end
end
