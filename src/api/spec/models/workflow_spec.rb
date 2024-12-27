RSpec.describe Workflow, :vcr do
  subject do
    described_class.new(workflow_instructions: yaml, scm_webhook: SCMWebhook.new(payload: extractor_payload), token: token, workflow_run: workflow_run)
  end

  let(:user) { create(:confirmed_user, :with_home, login: 'cameron') }
  let(:token) { create(:workflow_token, executor: user) }
  let!(:workflow_run) { create(:workflow_run, token: token) }

  describe '#call' do
    let(:yaml) do
      { 'steps' => [{ 'branch_package' => { 'source_project' => 'test-project', 'source_package' => 'test-package', 'target_project' => 'test-target-project',
                                            'target_package' => 'test-target-package' } }] }
    end

    context 'with an unsupported event filter' do
      let(:yaml) { { filters: { event: 'nonexistent' } } }
      let(:extractor_payload) do
        {
          scm: 'github',
          action: 'opened',
          event: 'pull_request'
        }
      end

      it 'does not run' do
        expect(subject.call).to be_nil
      end
    end

    context 'with GitHub "pull_request" event not matching the "push" event filter' do
      let(:yaml) { { filters: { event: 'push' } } }
      let(:extractor_payload) do
        {
          scm: 'github',
          action: 'opened',
          event: 'pull_request'
        }
      end

      it 'does not run' do
        expect(subject.call).to be_nil
      end
    end

    context 'with GitHub "push" event not matching the "pull_request" event filter' do
      let(:yaml) { { filters: { event: 'pull_request' } } }
      let(:extractor_payload) do
        {
          scm: 'github',
          event: 'push',
          ref: 'refs/heads/branch_123'
        }
      end

      it 'does not run' do
        expect(subject.call).to be_nil
      end
    end

    context 'with GitHub "push" event not matching the "tag_push" event filter' do
      let(:yaml) { { filters: { event: 'tag_push' } } }
      let(:extractor_payload) do
        {
          scm: 'github',
          event: 'push',
          ref: 'refs/heads/branch_123'
        }
      end

      it 'does not run' do
        expect(subject.call).to be_nil
      end
    end

    context 'with GitLab "Merge Request Hook" event not matching the "push" event filter' do
      let(:yaml) { { filters: { event: 'push' } } }
      let(:extractor_payload) do
        {
          scm: 'gitlab',
          event: 'Merge Request Hook'
        }
      end

      it 'does not run' do
        expect(subject.call).to be_nil
      end
    end

    context 'with GitLab "Push Hook" event not matching the "pull_request" event filter' do
      let(:yaml) { { filters: { event: 'pull_request' } } }
      let(:extractor_payload) do
        {
          scm: 'gitlab',
          event: 'Push Hook'
        }
      end

      it 'does not run' do
        expect(subject.call).to be_nil
      end
    end

    context 'with GitLab "Push Hook" event not matching the "tag_push" event filter' do
      let(:yaml) { { filters: { event: 'tag_push' } } }
      let(:extractor_payload) do
        {
          scm: 'gitlab',
          event: 'Push Hook'
        }
      end

      it 'does not run' do
        expect(subject.call).to be_nil
      end
    end

    context 'with GitHub "push" event for a tag' do
      let(:yaml) do
        { 'steps' => [{ 'branch_package' => { 'source_project' => 'test-project', 'source_package' => 'test-package' } }] }
      end
      let(:extractor_payload) do
        {
          scm: 'github',
          event: 'push',
          ref: 'refs/tags/release_abc',
          target_branch: '9e0ea1fd99c9000cbb8b8c9d28763d0ddace0b65'
        }
      end

      before do
        allow(subject.steps.first).to receive(:call)
      end

      it 'the workflow runs' do
        subject.call
        expect(subject.steps.first).to have_received(:call)
      end
    end

    context 'with GitLab "Tag Push Hook" event' do
      let(:yaml) do
        { 'steps' => [{ 'branch_package' => { 'source_project' => 'test-project', 'source_package' => 'test-package' } }] }
      end
      let(:extractor_payload) do
        {
          scm: 'gitlab',
          event: 'Tag Push Hook',
          ref: 'refs/tags/release_abc',
          target_branch: '9e0ea1fd99c9000cbb8b8c9d28763d0ddace0b65'
        }
      end

      before do
        allow(subject.steps.first).to receive(:call)
      end

      it 'the workflow runs' do
        subject.call
        expect(subject.steps.first).to have_received(:call)
      end
    end

    context 'with GitHub "pull_request" event matching the "merge_request" event filter alias' do
      let(:yaml) do
        { 'steps' => [{ 'branch_package' => { 'source_project' => 'test-project', 'source_package' => 'test-package' } }],
          'filters' => { 'event' => 'merge_request' } }
      end
      let(:extractor_payload) do
        {
          scm: 'github',
          action: 'opened',
          event: 'pull_request'
        }
      end

      before do
        allow(subject.steps.first).to receive(:call)
      end

      context 'when no workflow version is provided' do
        it 'the workflow runs' do
          subject.call
          expect(subject.steps.first).to have_received(:call)
        end
      end

      context 'when a workflow version is provided that does not support the alias' do
        subject do
          described_class.new(workflow_instructions: yaml, scm_webhook: SCMWebhook.new(payload: extractor_payload),
                              token: token, workflow_run: workflow_run, workflow_version_number: '1.0')
        end

        it 'the workflow does not run' do
          subject.call
          expect(subject.steps.first).not_to have_received(:call)
        end
      end
    end

    context 'when the webhook event is against none of the branches in the branches/ignore filters' do
      let(:yaml) do
        { 'steps' => [{ 'branch_package' => { 'source_project' => 'test-project', 'source_package' => 'test-package' } }],
          'filters' => { 'branches' => { 'ignore' => %w[something main] } } }
      end
      let(:extractor_payload) do
        {
          scm: 'github',
          action: 'opened',
          event: 'pull_request',
          target_branch: 'master'
        }
      end

      before do
        allow(subject.steps.first).to receive(:call)
      end

      it 'the workflow runs' do
        subject.call
        expect(subject.steps.first).to have_received(:call)
      end
    end

    context 'when the webhook event is against none of the branches in the branches/only filters' do
      let(:yaml) do
        { 'steps' => [{ 'branch_package' => { 'source_project' => 'test-project', 'source_package' => 'test-package' } }],
          'filters' => { 'branches' => { 'only' => %w[something main] } } }
      end
      let(:extractor_payload) do
        {
          scm: 'github',
          action: 'opened',
          event: 'pull_request',
          target_branch: 'master'
        }
      end

      before do
        allow(subject.steps.first).to receive(:call)
      end

      it 'the workflow does not run' do
        subject.call
        expect(subject.steps.first).not_to have_received(:call)
      end
    end

    context 'when the webhook event is against one of the branches in the branches/ignore filters' do
      let(:yaml) do
        { 'steps' => [{ 'branch_package' => { 'source_project' => 'test-project', 'source_package' => 'test-package' } }],
          'filters' => { 'branches' => { 'ignore' => %w[something main] } } }
      end
      let(:extractor_payload) do
        {
          scm: 'github',
          action: 'opened',
          event: 'pull_request',
          target_branch: 'main'
        }
      end

      before do
        allow(subject.steps.first).to receive(:call)
      end

      it 'the workflow does not run' do
        subject.call
        expect(subject.steps.first).not_to have_received(:call)
      end
    end

    context 'when the webhook event is against one of the branches in the branches/only filters' do
      let(:yaml) do
        { 'steps' => [{ 'branch_package' => { 'source_project' => 'test-project', 'source_package' => 'test-package' } }],
          'filters' => { 'branches' => { 'only' => %w[master develop] } } }
      end
      let(:extractor_payload) do
        {
          scm: 'github',
          action: 'opened',
          event: 'pull_request',
          source_branch: 'test_branch',
          target_branch: 'master'
        }
      end

      before do
        allow(subject.steps.first).to receive(:call)
      end

      it 'the workflow runs' do
        subject.call
        expect(subject.steps.first).to have_received(:call)
      end
    end

    context 'when the webhook event is not supported by the branches filter' do
      let(:yaml) do
        { 'steps' => [{ 'trigger_services' => { 'project' => 'test-project', 'package' => 'test-package' } }],
          'filters' => { 'branches' => { 'only' => ['develop'] } } }
      end

      let(:extractor_payload) do
        {
          scm: 'gitlab',
          event: 'Tag Push Hook',
          ref: 'refs/tags/release_abc',
          target_branch: '9e0ea1fd99c9000cbb8b8c9d28763d0ddace0b65'
        }
      end

      it 'is not valid and has an error message' do
        subject.valid?(:call)
        expect(subject.errors.full_messages.to_sentence).to eq('Filters for branches are not supported for the tag push event. ' \
                                                               "Documentation for filters: #{WorkflowFiltersValidator::DOCUMENTATION_LINK}")
      end
    end
  end

  describe '#steps' do
    let(:project) { create(:project, name: 'test-project', maintainer: user) }
    let(:package) { create(:package, name: 'test-package', project: project) }
    let(:extractor_payload) do
      {
        scm: 'github',
        action: 'opened',
        event: 'pull_request',
        pr_number: 1,
        target_repository_full_name: 'iggy/test-project'
      }
    end

    before do
      login user
    end

    context 'with a supported step' do
      let(:yaml) do
        { 'steps' => [{ branch_package: { source_project: project.name, source_package: package.name, target_project: project.name } }] }
      end

      it 'initializes the supported step objects' do
        expect(subject.steps.first).to be_a(Workflow::Step::BranchPackageStep)
      end

      # This example requires VCR
      it { expect { subject.call }.to change(WorkflowArtifactsPerStep, :count).by(1) }
    end

    context 'with several supported steps' do
      let(:yaml) do
        { 'steps' => [{ 'branch_package' => { source_project: project.name,
                                              source_package: package.name,
                                              target_project: project.name } },
                      { 'branch_package' => { source_project: project.name,
                                              source_package: package.name,
                                              target_project: project.name } }] }
      end

      it 'returns an array with two items' do
        expect(subject.steps.count).to be 2
      end
    end

    context 'with one unsupported step' do
      let(:yaml) do
        { 'steps' => [{ 'unsupported_step' => {} },
                      { 'branch_package' => { source_project: project.name,
                                              source_package: package.name,
                                              target_project: project.name } }] }
      end

      it 'returns an array with only one item' do
        expect(subject.steps.count).to be 1
      end

      # This example requires VCR
      it { expect { subject.call }.to change(WorkflowArtifactsPerStep, :count).by(1) }
    end

    context 'with no steps specified' do
      let(:yaml) do
        {}
      end

      it 'returns an empty array' do
        expect(subject.steps).to be_empty
      end

      # This example requires VCR
      it { expect { subject.call }.not_to change(WorkflowArtifactsPerStep, :count) }
    end

    context 'with step with invalid intructions' do
      let(:yaml) do
        { 'steps' => [{ branch_package: { source_package: package.name, target_project: project.name } }] }
      end

      it 'initializes the supported step objects' do
        expect(subject.steps.first).to be_a(Workflow::Step::BranchPackageStep)
      end

      # This example requires VCR
      it { expect { subject.call }.not_to change(WorkflowArtifactsPerStep, :count) }
    end

    context 'with step with invalid project name' do
      let(:yaml) do
        { 'steps' => [{ 'branch_package' => { source_project: '0', # invalid project name
                                              source_package: package.name,
                                              target_project: project.name } }] }
      end

      it 'initializes the supported step objects' do
        expect(subject.steps.first).to be_a(Workflow::Step::BranchPackageStep)
      end

      # This example requires VCR
      it { expect { subject.call }.not_to change(WorkflowArtifactsPerStep, :count) }
    end
  end

  describe '#content-selector-filters' do
    let(:extractor_payload) do
      {
        scm: 'github',
        action: 'opened',
        event: 'pull_request'
      }
    end

    context 'with filters having valid values' do
      let(:yaml) do
        {
          'filters' => {
            'event' => 'push',
            'branches' => { 'only' => %w[master staging] }
          }
        }
      end

      it 'returns filters' do
        expect(subject.filters).to eq({ event: 'push',
                                        branches: { only: %w[master staging] } })
      end
    end

    context 'without filters' do
      let(:yaml) do
        {}
      end

      it 'returns nothing' do
        expect(subject.filters).to eq({})
      end
    end
  end
end
