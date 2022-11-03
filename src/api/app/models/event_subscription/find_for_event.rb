class EventSubscription
  class FindForEvent
    attr_reader :event

    def initialize(event)
      @event = event
    end

    def subscriptions(channel = :instant_email, debug = false)
      if debug
        ActiveRecord::Base.logger.silence do
          receive_subscriptions(channel, true)
        end
      else
        receive_subscriptions(channel)
      end
    end

    private

    def receive_subscriptions(channel, debug = false)
      @debug = debug
      receivers_and_subscriptions = {}

      event.class.receiver_roles.each do |receiver_role|
        # Find the users/groups who are receivers for this event
        receivers = event.send("#{receiver_role}s")
        next if receivers.blank?

        puts "\n~~~~~~ START `subscriptions` for receiver_role '#{receiver_role}' and channel '#{channel}' ~~~~~~\n" if @debug
        puts "  ----- START `expand_receivers` ----- " if @debug
        puts "    Expanding receivers for groups and users with 'receiver_role': #{receiver_role}" if @debug
        receivers = expand_receivers(receivers, channel)
        if @debug
          puts "    ..... START: Result of expanding `receivers` ..... "
          ap receivers if @debug
          puts "    ..... END: Result of expanding `receivers` ..... "
          puts '  ----- END `expand_receivers` -----'
        end

        options = { eventtype: event.eventtype, receiver_role: receiver_role, channel: channel }
        # Find the default subscription for this eventtype and receiver_role
        default_subscription = EventSubscription.defaults.find_by(options)
        if @debug
          puts "  Fetch `default_subscriptions` with the following parameters: "
          ap options
          if default_subscription.present?
            puts "  Found the following `default_subscription`: "
            ap default_subscription.attributes
          else
            puts '  No default subscription found.'
          end
        end

        puts "  ----- START iteration over `receivers` ------" if @debug
        receivers.each do |receiver|
          puts "    ----- START for `receiver` '#{receiver.is_a?(User) ? receiver.name : receiver.title}' -----" if @debug
          # Prevent multiple enabled subscriptions for the same subscriber & eventtype
          # Also skip if the receiver is the originator of this event
          if receivers_and_subscriptions[receiver].present? || receiver == event.originator
            puts "      Skip receiver '#{receiver.is_a?(User) ? receiver.name : receiver.title}', since it is the originator of the event." if @debug && receiver == event.originator
            if @debug && receivers_and_subscriptions[receiver].present?
              puts "      Skip receiver '#{receiver.is_a?(User) ? receiver.name : receiver.title}', since it is already included in the final list of `receivers_and_subscriptions`: "
              ap receivers_and_subscriptions
            end
            next
          end

          # Try to find the subscription for this receiver
          receiver_subscription = EventSubscription.for_subscriber(receiver).find_by(options)
          if @debug
            puts "      Search for subscription for #{receiver.is_a?(User) ? receiver.name : receiver.title} with the following parameters: "
            ap options
          end

          if receiver_subscription.present?
            # Use the receiver's subscription if it exists
            if @debug
              puts "      Found the following subscription: "
              ap receiver_subscription.attributes
            end
            receivers_and_subscriptions[receiver] = receiver_subscription if receiver_subscription.enabled?
            puts "      Subscription is enabled, adding to `receivers_and_subscriptions`..." if @debug && receiver_subscription.enabled?
          # Only check the default_subscription if there is no receiver's subscription
          elsif default_subscription.present? && default_subscription.enabled?
            if @debug
              puts "      Adding `default_subscription` to `receivers_and_subscriptions` for '#{receiver.is_a?(User) ? receiver.name : receiver.title}'"
              ap default_subscription.attributes
            end
            # Add a new subscription for the receiver based on the default subscription
            receivers_and_subscriptions[receiver] = EventSubscription.new(
              eventtype: default_subscription.eventtype,
              receiver_role: default_subscription.receiver_role,
              channel: default_subscription.channel,
              subscriber: receiver
            )
          end
          puts "    ----- END for `receiver` '#{receiver.is_a?(User) ? receiver.name : receiver.title}' -----" if @debug
        end
        puts "  ~~~~~~ END `subscriptions` for receiver_role '#{receiver_role}' and channel '#{channel}' ~~~~~~ \n" if @debug
      end
      if @debug
        puts "\n====== START RESULT `receivers_and_subscriptions` ======"
        ap receivers_and_subscriptions.values.flatten
        puts "====== END RESULT `receivers_and_subscriptions` ======"
      end

      receivers_and_subscriptions.values.flatten
    end

    def expand_receivers(receivers, channel)
      receivers.inject([]) do |new_receivers, receiver|
        case receiver
        when User
          new_receivers << receiver if receiver.is_active?
          if @debug
            puts "    Receiver is a user. Checking if user is active..."
            puts "    User '#{receiver.login}' is #{receiver.is_active? ? 'active' : 'inactive'}."
            puts "    Adding '#{receiver.login}' to `new_receivers`."
          end
        when Group
          puts "    ----- START `expand_receivers_for_groups` -----" if @debug
          new_receivers += expand_receivers_for_groups(new_receivers, receiver, channel)
          puts "    ----- END `expand_receivers_for_groups` -----" if @debug
        end

        new_receivers
      end
    end

    def expand_receivers_for_groups(_new_receivers, receiver, channel)
      puts "      Receiver is a group. Expanding users from group '#{receiver.title}'..." if @debug
      # We don't subscribe Groups so we have to get the group's users to get the subscriptions
      if event.instance_of?(Event::RelationshipCreate) || event.instance_of?(Event::RelationshipDelete)
        puts "      Event is of type 'RelationshipCreate' or 'RelationshipDelete'. Expanding all users of the group..." if @debug
        puts "      Following users are going to be expanded from group: #{receiver.users.map(&:login).join(', ')}" if @debug
        return receiver.users
      end
      # We don't split events which come through the web channel, for a group subscriber.
      # They are split in the NotificationService::WebChannel service, if needed.
      if channel == :web || receiver.email.present?
        puts "      Channel is of type 'web'. Not going to expand the users from group. Continue with group '#{receiver.title}'." if @debug && channel == :web
        puts "      Group has an email address assigned. Not going to expand users from group. Continue with group '#{receiver.title}'." if @debug && receiver.email.present?
        return [receiver]
      end

      puts "      Expanding group users that are subscribed to emails for group #{receiver.title}." if @debug
      puts "      Following users are going to be expanded from group: #{receiver.email_users.map(&:login).join(', ')}" if @debug
      receiver.email_users
    end
  end
end
