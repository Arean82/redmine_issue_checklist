require File.expand_path('../../test_helper', __FILE__)

class IssueChecklistsControllerTest < ActionController::TestCase
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules

  def setup
    @request.session[:user_id] = 1 # Admin
    @issue = Issue.find(1)
    @item = @issue.checklist.create!(subject: 'Existing item', is_done: false)
  end

  def test_toggle_done
    post :done, params: { checklist_item_id: @item.id }
    assert_response :success
    assert_equal true, @item.reload.is_done
  end

  def test_quick_add
    post :quick_add, params: { issue_id: @issue.id, subject: 'New Quick Task', is_section: '0' }
    assert_redirected_to issue_path(@issue)
    assert_equal 'New Quick Task', @issue.checklist.last.subject
  end

  def test_batch_import
    items = [
      { subject: 'Task A', is_section: '0', is_done: '0' },
      { subject: 'Section B', is_section: '1', is_done: '0' }
    ]
    post :batch_import, params: { issue_id: @issue.id, mode: 'append', items: items }, format: :json
    assert_response :success
    assert_includes @issue.checklist.reload.map(&:subject), 'Task A'
    assert_includes @issue.checklist.map(&:subject), 'Section B'
  end

  def test_export_markdown
    get :export, params: { issue_id: @issue.id }
    assert_response :success
    assert_equal 'text/markdown; charset=utf-8', @response.media_type
  end

  def test_api_index
    get :index, params: { issue_id: @issue.id }, format: :json
    assert_response :success
    json = JSON.parse(@response.body)
    assert json.is_a?(Array)
    assert_equal 1, json.size
  end
end
