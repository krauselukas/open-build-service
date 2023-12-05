class Appeal < ApplicationRecord
  belongs_to :appellant, required: true, class_name: 'User'
  belongs_to :decision, required: true

  validates_presence_of :reason

  after_create :create_event

  private

  def create_event
    Event::AppealCreated.create(event_parameters)
  end

  def event_parameters
    { id: id, appellant_id: appellant.id, decision_id: decision.id, reason: reason }
  end
end

# == Schema Information
#
# Table name: appeals
#
#  id           :integer          not null, primary key
#  reason       :text(65535)      not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  appellant_id :integer          not null
#  decision_id  :integer          not null
#
