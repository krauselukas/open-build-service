class BsRequestPolicy < ApplicationPolicy
  def create?
    # new request should not have an id (BsRequest#number)
    return false if record.number

    return true if [nil, user.login].include?(record.approver) || user.is_admin?

    false
  end

  def handle_request?
    record.state.in?(%i[new review declined]) && (target_maintainer? || author?)
  end

  def add_reviews?
    has_open_reviews = record.reviews.where(state: 'new').any? { |review| review.matches_user?(user) }
    record.state.in?(%i[new review]) && (author? || target_maintainer? || has_open_reviews.present?)
  end

  def revoke_request?
    author? && record.state.in?(%i[new review declined])
  end

  def report?
    ensure_logged_in!(user, {})
  end

  def target_maintainer?
    record.bs_request_actions.all? { |action| action.is_target_maintainer?(user) }
  end

  private

  def author?
    record.creator == user.login
  end
end
