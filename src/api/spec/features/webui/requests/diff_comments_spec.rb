require 'browser_helper'

RSpec.describe 'Comments with diff', :js, :vcr do
  let(:admin) { create(:admin_user, login: 'Admin') }
  let(:target_project) { create(:project, name: 'target_project') }
  let(:source_project) { create(:project, :as_submission_source, name: 'source_project') }
  let(:target_package) { create(:package, name: 'target_package', project: target_project) }
  let(:source_package) do
    create(:package_with_files,
           name: 'package_a',
           project: source_project,
           changes_file_content: '- Fixes ------')
  end
  let(:bs_request) do
    create(:bs_request_with_submit_action,
           target_package: target_package,
           source_package: source_package)
  end

  context 'reply comment' do
    describe 'when under the beta program' do
      let!(:comment) { create(:comment, commentable: bs_request.bs_request_actions.first, diff_file_index: 0, diff_line_number: 1, user: admin) }

      before do
        Flipper.enable(:request_show_redesign, admin)
        login admin
        visit request_show_path(bs_request)

        click_on "reply_button_of_#{comment.id}"
        within("#reply_for_#{comment.id}_form") do
          fill_in "reply_for_#{comment.id}_body", with: 'This is a new reply'
          click_on 'Add comment'
        end
      end

      it 'displays the changes after adding a new comment' do
        expect(page).to have_text('This is a new reply')
        expect(page).to have_text('target_project/target_package > package_a.changes')
      end
    end
  end

  describe 'create diff comment' do
    before do
      Flipper.enable(:request_show_redesign, admin)
      login admin

      visit request_changes_path(bs_request)
      sleep(0.5) # wait for file diff to be loaded
      find_by_id('diff_1_n2').hover # make add comment link visible
      within('#commentdiff_1_n2') do
        find('a', class: 'line-new-comment').click
        sleep(0.5) # wait for comment box to appear
        fill_in 'new_comment_diff_1_n2_body', with: 'My test diff comment'
        find('input[type="submit"]').click
        sleep(0.5) # wait for comment to be created
      end
    end

    it 'displays the comment on the file diff in the changes tab' do
      expect(page).to have_css("#comment-#{Comment.last.id}-body", text: 'My test diff comment')
    end

    it 'displays the comment in the conversation tab' do
      visit request_show_path(bs_request)
      expect(page).to have_css("#comment-#{Comment.last.id}-body", text: 'My test diff comment')
      expect(page).to have_css("#comment-#{Comment.last.id}-bubble", text: 'target_project/target_package > package_a.spec')
    end
  end

  describe 'diff comment in legacy view' do
    let!(:comment) { create(:comment, commentable: bs_request.bs_request_actions.first, diff_file_index: 0, diff_line_number: 1, user: admin) }

    before do
      login admin
      visit request_show_path(bs_request)
    end

    it 'displays the comment with a hint to the corresponding file and line' do
      expect(page).to have_css('#comments-list', text: "Inline comment for target: 'target_project/target_package', file: 'package_a.changes', and line: 1.")
    end
  end
end
