class Event::AppealCreated < Base
  receiver_roles :moderator

  self.description = 'A reported user has appealed the decision'

  payload_keys :id, :appellant_id, :decision_id, :reason
end
