class AddProFeaturesToIssueChecklist < ActiveRecord::Migration[6.0]
  def up
    # 1. Checklist Template Categories
    unless table_exists?(:checklist_template_categories)
      create_table :checklist_template_categories do |t|
        t.string :name, null: false
        t.integer :position, default: 1
        t.timestamps
      end
    end

    # 2. Checklist Templates
    unless table_exists?(:checklist_templates)
      create_table :checklist_templates do |t|
        t.string :name, null: false
        t.references :project, index: true
        t.references :category, index: true
        t.references :user, index: true
        t.references :tracker, index: true
        t.boolean :is_public, default: true
        t.boolean :is_default, default: false
        t.text :template_items
        t.timestamps
      end
    end

    # 3. Add is_section to issue_checklists if not present
    if table_exists?(:issue_checklists) && !column_exists?(:issue_checklists, :is_section)
      add_column :issue_checklists, :is_section, :boolean, default: false
    end
  end

  def down
    if column_exists?(:issue_checklists, :is_section)
      remove_column :issue_checklists, :is_section
    end
    drop_table :checklist_templates if table_exists?(:checklist_templates)
    drop_table :checklist_template_categories if table_exists?(:checklist_template_categories)
  end
end
