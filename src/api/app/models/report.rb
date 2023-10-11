# Report class flags abusive content, be it projects, packages, users or comments
class Report < ApplicationRecord
  validates :reason, length: { maximum: 65_535 }
  validates :reportable_type, length: { maximum: 255 }

  belongs_to :user, optional: false
  belongs_to :reportable, polymorphic: true, optional: true

  belongs_to :decision, optional: true

  after_create :create_event

  scope :without_decision, -> { where(decision: nil) }

  private

  def create_event
    case reportable_type
    when 'Comment'
      Event::ReportForComment.create(event_parameters_for_comment(commentable: reportable.commentable))
    when 'Package'
      Event::ReportForPackage.create(event_parameters.merge(package_name: reportable.name,
                                                            project_name: reportable.project.name))
    when 'Project'
      Event::ReportForProject.create(event_parameters.merge(project_name: reportable.name))
    when 'User'
      Event::ReportForUser.create(event_parameters.merge(user_login: reportable.login))
    end
  end

  def event_parameters
    { id: id, user_id: user_id, reportable_id: reportable_id, reportable_type: reportable_type, reason: reason }
  end

  def event_parameters_for_comment(commentable:)
    case commentable
    when BsRequest
      event_parameters.merge(commentable_type: commentable.class.name, bs_request_number: commentable.number)
    when BsRequestAction
      event_parameters.merge(commentable_type: commentable.class.name, bs_request_number: commentable.bs_request.number,
                             bs_request_action_id: commentable.id)
    when Package
      event_parameters.merge(commentable_type: commentable.class.name, package_name: commentable.name,
                             project_name: commentable.project.name)
    when Project
      event_parameters.merge(commentable_type: commentable.class.name, project_name: commentable.name)
    end
  end
end

# == Schema Information
#
# Table name: reports
#
#  id              :bigint           not null, primary key
#  reason          :text(65535)
#  reportable_type :string(255)      indexed => [reportable_id]
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  decision_id     :bigint           indexed
#  reportable_id   :integer          indexed => [reportable_type]
#  user_id         :integer          not null, indexed
#
# Indexes
#
#  index_reports_on_decision_id  (decision_id)
#  index_reports_on_reportable   (reportable_type,reportable_id)
#  index_reports_on_user_id      (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (decision_id => decisions.id) ON DELETE => nullify
#  fk_rails_...  (user_id => users.id)
#
