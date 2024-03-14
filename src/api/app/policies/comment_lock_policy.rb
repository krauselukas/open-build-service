class CommentLockPolicy < ApplicationPolicy
  def create?
    return false unless Flipper.enabled?(:content_moderation, user)

    return true if user.is_moderator? || user.is_admin?

    case record
    # Maintainers of Package or Project can lock comments
    when Package, Project
      return record.maintainers.include?(user)
    # Request receivers (maintainers of target package) can also lock comments
    when BsRequest
      return BsRequestPolicy.new(user, record).target_maintainer?
    when BsRequestAction
      return record.bs_request.is_target_maintainer?(user)
    end

    false
  end

  def destroy?
    create?
  end
end
