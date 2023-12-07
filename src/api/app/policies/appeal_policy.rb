class AppealPolicy < ApplicationPolicy
  def new?
    create?
  end

  def show?
    return true if record.appellant == user

    user.is_admin? || user.is_moderator? || user.is_staff?
  end

  def create?
    return false if record.decision.kind? == 'cleared'

    report = record.decision.reports.first

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
