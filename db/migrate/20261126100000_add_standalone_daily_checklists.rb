class AddStandaloneDailyChecklists < ActiveRecord::Migration[6.0]
  def up
    # Make issue_id nullable on issue_checklists to support standalone daily/team checklists
    change_column_null :issue_checklists, :issue_id, true

    unless column_exists?(:issue_checklists, :user_id)
      add_column :issue_checklists, :user_id, :integer
      add_index :issue_checklists, :user_id
    end

    unless column_exists?(:issue_checklists, :is_daily)
      add_column :issue_checklists, :is_daily, :boolean, default: false
    end

    unless column_exists?(:issue_checklists, :last_done_date)
      add_column :issue_checklists, :last_done_date, :date
    end

    unless column_exists?(:issue_checklists, :converted_issue_id)
      add_column :issue_checklists, :converted_issue_id, :integer
      add_index :issue_checklists, :converted_issue_id
    end
  end

  def down
    remove_column :issue_checklists, :converted_issue_id if column_exists?(:issue_checklists, :converted_issue_id)
    remove_column :issue_checklists, :last_done_date if column_exists?(:issue_checklists, :last_done_date)
    remove_column :issue_checklists, :is_daily if column_exists?(:issue_checklists, :is_daily)
    remove_column :issue_checklists, :user_id if column_exists?(:issue_checklists, :user_id)
  end
end
