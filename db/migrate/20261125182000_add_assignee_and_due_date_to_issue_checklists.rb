class AddAssigneeAndDueDateToIssueChecklists < ActiveRecord::Migration[6.0]
  def up
    unless column_exists?(:issue_checklists, :assigned_to_id)
      add_column :issue_checklists, :assigned_to_id, :integer
      add_index :issue_checklists, :assigned_to_id
    end
    unless column_exists?(:issue_checklists, :due_date)
      add_column :issue_checklists, :due_date, :date
    end
  end

  def down
    remove_column :issue_checklists, :due_date if column_exists?(:issue_checklists, :due_date)
    remove_column :issue_checklists, :assigned_to_id if column_exists?(:issue_checklists, :assigned_to_id)
  end
end
