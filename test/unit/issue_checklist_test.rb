require File.expand_path('../../test_helper', __FILE__)

class IssueChecklistTest < ActiveSupport::TestCase
  fixtures :projects, :users, :issues, :trackers

  def setup
    @project = Project.find(1)
    @issue = Issue.find(1)
    @user = User.find(1)
  end

  def test_create_checklist_item
    item = @issue.checklist.create(
      subject: 'Verify test checklist item',
      is_done: false,
      is_section: false
    )
    assert item.persisted?
    assert_equal '[ ] Verify test checklist item', item.info
  end

  def test_section_header_item
    item = @issue.checklist.create(
      subject: 'Backend Phase',
      is_section: true,
      is_done: false
    )
    assert item.persisted?
    assert_equal '# Backend Phase', item.info
  end

  def test_checklist_with_assignee_and_due_date
    item = @issue.checklist.create(
      subject: 'Deploy staging',
      assigned_to: @user,
      due_date: Date.today + 3.days
    )
    assert item.persisted?
    assert_equal @user, item.assigned_to
    assert_includes item.info, "(Assignee: #{@user.name})"
  end

  def test_checklist_progress_bar_calculation_in_query
    query = IssueQuery.new
    col = query.available_columns.find { |c| c.name == :checklist }
    assert_not_nil col

    # Clean checklist on issue
    @issue.checklist.destroy_all
    @issue.checklist.create!(subject: 'T1', is_done: true, is_section: false)
    @issue.checklist.create!(subject: 'T2', is_done: false, is_section: false)

    output = query.value_object(@issue, col)
    assert_includes output, '50%'
    assert_includes output, '1/2'
    assert_includes output, 'checklist-table-cell'
  end

  def test_checklist_template_items_parser
    template = ChecklistTemplate.create!(
      name: 'Release Template',
      template_items: "Step 1\n# Testing Section\nStep 2"
    )
    items = template.items
    assert_equal 3, items.size
    assert_equal 'Step 1', items[0]['subject']
    assert_equal false, items[0]['is_section']
    assert_equal 'Testing Section', items[1]['subject']
    assert_equal true, items[1]['is_section']
  end

  def test_auto_tracker_default_checklist
    tracker = Tracker.find(1)
    ChecklistTemplate.create!(
      name: 'Default Bug Template',
      tracker: tracker,
      is_default: true,
      template_items: "Reproduce bug\nFix issue\nAdd regression test"
    )

    new_issue = Issue.new(project: @project, tracker: tracker, author: @user, subject: 'New Bug Report')
    assert_equal 3, new_issue.checklist.size
    assert_equal 'Reproduce bug', new_issue.checklist.first.subject
  end
end
