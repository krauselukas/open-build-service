# frozen_string_literal: true

class SetBoundariesToIssueTrackersRegex < ActiveRecord::Migration[6.1]
  # TODO: set boundaries for the rest of issue trackers' regexs too
  def up
    issue_trackers = IssueTracker.where(name: 'i')
    regex = issue_trackers.first.regex

    issue_trackers.update_all(regex: "\b#{regex}\b")

    # IssueTracker.where(name: 'i').each do |issue_tracker|
    #   binding.pry
    #   issue_tracker.update(regex: "\b#{issue_tracker.regex}\b")
    # end
  end

  def down
    IssueTracker.where(name: 'i').each do |issue_tracker|
      issue_tracker.update(regex: issue_tracker.regex.gsub(/\A\b/, ''))
      issue_tracker.update(regex: issue_tracker.regex.gsub(/\b\z/, ''))
    end
  end
end
