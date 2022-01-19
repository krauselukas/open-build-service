require 'rails_helper'
require Rails.root.join('db/data/20220119085829_set_boundaries_to_issue_trackers_regex.rb')

RSpec.describe SetBoundariesToIssueTrackersRegex do
  describe '.up' do
    let!(:issue_tracker) { IssueTracker.find_by(name: 'i') }

    subject! { SetBoundariesToIssueTrackersRegex.new.up }

    it 'concat \b before and after the regex' do
      expect(issue_tracker.regex).to eq('\bi#(\d+)\b')
    end
  end

  describe '.down' do
    #let!(:issue_tracker) { create(:issue_tracker, regex:'\bi#(\d+)\b' ) }
    let!(:issue_tracker) { IssueTracker.find_by(name: 'i') }

    subject! { SetBoundariesToIssueTrackersRegex.new.up }

    it 'remove \b from the beginning and end of the regex' do
      expect(issue_tracker.regex).to eq('i#(\d+)')
    end
  end
end
