class NotificationPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.for_web.where(subscriber_type: 'User', subscriber_id: user.id).or(scope.where(subscriber_type: 'Group', subscriber_id: user.groups.ids))
    end
  end
end
