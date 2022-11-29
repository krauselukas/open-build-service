# frozen_string_literal: true

class RenameWatcherReceiverRoleForEventSubscriptions < ActiveRecord::Migration[7.0]
  def up
    EventSubscription.where(receiver_role: ['watcher', 'source_watcher', 'target_watcher']).find_in_batches do |batch|
      batch.each do |event_subscription|
        case event_subscription.receiver_role
        when 'watcher'
          event_subscription.update(receiver_role: 'project_watcher')
        when 'source_watcher'
          event_subscription.update(receiver_role: 'source_project_watcher')
        when 'target_watcher'
          event_subscription.update(receiver_role: 'target_project_watcher')
        end
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
