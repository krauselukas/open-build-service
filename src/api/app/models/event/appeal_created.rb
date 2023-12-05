class Event::AppealCreated < Event::Base
  receiver_roles :moderator

  self.description = 'A reported user has appealed the decision'

  payload_keys :id, :appellant_id, :decision_id, :reason

  def parameters_for_notification
    super.merge(notifiable_type: 'Appeal')
  end
end
