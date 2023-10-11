class EventSubscription
  class Form
    attr_reader :subscriber

    def initialize(subscriber = nil)
      @subscriber = subscriber
    end

    def subscriptions_by_event
      event_classes = Event::Base.notification_events
      event_classes.filter_map do |event_class|
        EventSubscription::ForEventForm.new(event_class, subscriber).call if show_form_for_create_report_event?(event_class: event_class, subscriber: subscriber)
      end
    end

    def update!(subscriptions_params)
      subscriptions_params.each do |_i, subscription_params|
        subscription = find_or_initialize_subscription(
          subscription_params[:eventtype],
          subscription_params[:receiver_role],
          subscription_params[:channel]
        )

        subscription.enabled = subscription_params[:enabled].present?
        subscription.save!
      end
    end

    private

    def find_or_initialize_subscription(eventtype, receiver_role, channel)
      opts = { eventtype: eventtype, receiver_role: receiver_role, channel: channel }

      if subscriber.is_a?(User) && subscriber.is_active?
        opts[:user] = subscriber
      elsif subscriber.is_a?(Group)
        opts[:group] = subscriber
      elsif subscriber.nil?
        opts[:user] = nil
        opts[:group] = nil
      end

      EventSubscription.find_or_initialize_by(opts)
    end

    def show_form_for_create_report_event?(event_class:, subscriber:)
      if event_class.name.in?(['Event::ReportForProject', 'Event::ReportForPackage', 'Event::ReportForComment', 'Event::ReportForUser'])
        # There is no subscriber for the global subscription configuration
        return false if subscriber.blank?
        return false unless ReportPolicy.new(subscriber, Report).notify?
      end

      true
    end
  end
end
