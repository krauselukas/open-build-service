require 'rails_helper'
require Rails.root.join('db/data/20220126223735_add_word_boundary_to_issue_tracker_regex.rb')

RSpec.describe AddWordBoundaryToIssueTrackerRegex, type: :migration do
  let!(:issue_tracker) { IssueTracker.create(name: 'foo', kind: 'bugzilla', description: 'this is a description',
                                             url: 'http://foo.bar', show_url: 'http://foo.bar', regex: 'foo#(\d+)',
                                             label: 'foo#\#@@@') }

  # DatabaseCleaner does not clean the issue_trackers table, we have to do it manually
  after(:each) do
    IssueTracker.last.delete
  end

  describe '.up' do
    before do
      AddWordBoundaryToIssueTrackerRegex.new.up
    end

    it 'concat \b before and after the regex' do

      expect(issue_tracker.reload.regex).to match("\bfoo#(\\d+)\b")
    end
  end

  describe '.down' do
    before do
      AddWordBoundaryToIssueTrackerRegex.new.down
    end

    it 'remove \b from the beginning and end of the regex' do
      expect(issue_tracker.reload.regex).to eq('foo#(\d+)')
    end
  end
end
