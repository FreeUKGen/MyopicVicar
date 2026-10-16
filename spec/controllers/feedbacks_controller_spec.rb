require 'spec_helper'

RSpec.describe FeedbacksController, type: :controller do
  describe '#feedback_params (strong parameters)' do
    before do
      controller.params = ActionController::Parameters.new(
        feedback: {
          title: 'Broken link',
          body: 'The link on this page is broken',
          feedback_time: '2024-01-01T00:00:00Z',
          user_id: 'u1',
          session_id: 'sess1',
          problem_page_url: '/somewhere',
          previous_page_url: '/somewhere-else',
          feedback_type: 'issue',
          screenshots: ['file1.png'],
          # attacker-supplied values that are not submitted by the feedback form
          archived: true,
          keep: true,
          github_issue_url: 'http://evil.example.com',
          contact_action_sent_to_userid: 'admin',
          _id: 'a-different-id'
        }
      )
    end

    it 'permits the fields the feedback form submits' do
      permitted = controller.send(:feedback_params)

      expect(permitted.permitted?).to be true
      expect(permitted[:title]).to eq('Broken link')
      expect(permitted[:body]).to eq('The link on this page is broken')
      expect(permitted[:screenshots]).to eq(['file1.png'])
    end

    it 'strips fields that are not submitted by the feedback form' do
      permitted = controller.send(:feedback_params)

      expect(permitted.to_h.keys).not_to include(
        'archived', 'keep', 'github_issue_url', 'contact_action_sent_to_userid', '_id'
      )
    end
  end

  describe '#new_params (strong parameters, top-level params)' do
    it 'permits only the query params problem_url/suggestion_url construct' do
      controller.params = ActionController::Parameters.new(
        controller: 'feedbacks',
        action: 'new',
        utf8: '✓',
        report_session_id: 'sess1',
        user_id: 'u1',
        problem_page_url: '/somewhere',
        previous_page_url: '/somewhere-else',
        feedback_type: 'issue',
        feedback_time: '2024-01-01T00:00:00Z',
        # attacker-supplied query param not part of the problem_url/suggestion_url helpers
        admin: true
      )

      permitted = controller.send(:new_params)

      expect(permitted.permitted?).to be true
      expect(permitted[:session_id]).to eq('sess1')
      expect(permitted[:user_id]).to eq('u1')
      expect(permitted[:problem_page_url]).to eq('/somewhere')
      expect(permitted.to_h.keys).not_to include(
        'utf8', 'controller', 'action', 'report_session_id', 'admin'
      )
    end
  end
end
