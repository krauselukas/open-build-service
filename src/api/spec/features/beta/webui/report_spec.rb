require 'browser_helper'

RSpec.describe 'Report', :js, :vcr do
  before do
    Flipper.enable(:content_moderation)
  end

  let(:reporter) { create(:confirmed_user, login: 'foo') }
  let(:moderator) { create(:moderator, login: 'baz') }
  let(:maintainer) { create(:confirmed_user, login: 'bar') }

  describe 'Project' do
    let(:project) { create(:project, name: 'against_the_rules', maintainer: maintainer) }

    context 'reporting' do
      context 'user without any role' do
        before do
          login(reporter)
          visit project_show_path(project)
        end

        it 'creates the report' do
          click_link 'Report Project'
          find_by_id('report_category_forbidden_license').click
          fill_in id: 'report_reason', with: 'This project does not follow the rules!'
          click_button('Submit')

          expect(page).to have_text('Project reported successfully')
          expect(Report.count).to eq(1)
          page.refresh
          expect(page).to have_text('You reported this project.')
          expect(page).not_to have_link('Report Project')
        end
      end

      context 'user with maintainer role' do
        before do
          login(maintainer)
          visit project_show_path(project)
        end

        it 'can not report' do
          expect(page).not_to have_link('Report Project')
        end
      end

      context 'user with admin role' do
        let(:admin) { create(:admin_user, login: 'Admin') }

        before do
          login(admin)
          visit project_show_path(project)
        end

        it 'can not report' do
          expect(page).not_to have_link('Report Project')
        end
      end
    end

    context 'moderating' do
      let!(:report_for_project) { create(:report, reportable: project, reason: 'This project does not follow the rules!', user: reporter) }

      before do
        login(moderator)
        visit project_show_path(project)
      end

      it 'creates the decision' do
        expect(page).to have_text('This project has 1 report .')
        click_link('1 report')
        fill_in id: 'decision_reason', with: 'Correct, license is forbidden.'
        select 'favor', from: 'decision[kind]'
        click_button('Submit')

        expect(page).to have_text('Decision created successfully')
        expect(Decision.count).to eq(1)
      end
    end
  end

  describe 'Package' do
    # TODO
  end

  describe 'Comment' do
    # TODO
  end

  describe 'User' do
    # TODO
  end
end
