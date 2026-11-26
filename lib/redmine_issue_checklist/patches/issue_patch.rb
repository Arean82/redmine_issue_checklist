module RedmineIssueChecklist
  module Patches
    module IssuePatch
      def self.included(base)
        base.class_eval do
          has_many :checklist, class_name: 'IssueChecklist', dependent: :destroy
          after_initialize :apply_tracker_default_checklist, if: :new_record?

          alias_method :copy_from_without_checklist, :copy_from
          alias_method :copy_from, :copy_from_with_checklist

          validate :validate_checklist_completion_before_closing
          after_save :sync_converted_checklist_parent_item
        end
      end

      def validate_checklist_completion_before_closing
        return unless closing?

        settings = RedmineIssueChecklist.settings
        block_closure = settings.is_a?(Hash) && (settings[:block_issue_closure].to_s == '1' || settings['block_issue_closure'].to_s == '1')
        return unless block_closure

        open_items = checklist.reject(&:is_section).reject(&:is_done)
        if open_items.any?
          items_list = open_items.map(&:subject).join(', ')
          errors.add(:base, l(:error_cannot_close_issue_with_open_checklists, items: items_list))
        end
      end

      def apply_tracker_default_checklist
        return unless tracker_id.present?
        return if checklist.any?

        default_template = ChecklistTemplate.default_templates.for_tracker(tracker_id).first
        if default_template.present?
          default_template.items.each_with_index do |item, idx|
            checklist.build(
              subject: item['subject'] || item[:subject],
              is_done: item['is_done'] || item[:is_done] || false,
              is_section: item['is_section'] || item[:is_section] || false,
              position: idx + 1
            )
          end
        end
      end

      def copy_from_with_checklist(arg, options = {})
        copy_from_without_checklist(arg, options)
        issue = arg.is_a?(Issue) ? arg : Issue.visible.find(arg)
        self.checklist = issue.checklist.map(&:dup)
        self.checklist.each do |object|
          object.is_done = false
        end
        self
      end

      def update_checklist_items(checklist_items, create_journal = false)
        checklist_items ||= []
        old_checklist = checklist.collect(&:info).join("\n")

        existing_items = checklist.to_a
        updated_ids = []

        checklist_items.each_with_index do |cli, idx|
          cli_hash = cli.respond_to?(:to_unsafe_h) ? cli.to_unsafe_h : cli.to_h
          item_id = cli_hash[:id] || cli_hash['id']
          item = existing_items.detect { |ci| ci.id.to_s == item_id.to_s } if item_id.present?

          is_done_val = cli_hash[:is_done] == '1' || cli_hash['is_done'] == '1' || cli_hash[:is_done] == true || cli_hash['is_done'] == true
          is_sec_val = cli_hash[:is_section] == '1' || cli_hash['is_section'] == '1' || cli_hash[:is_section] == true || cli_hash['is_section'] == true
          subj_val = cli_hash[:subject] || cli_hash['subject']

          if item
            item.subject = subj_val
            item.is_done = is_done_val
            item.is_section = is_sec_val
            item.position = idx + 1
            item.save if item.changed?
            updated_ids << item.id
          else
            new_item = IssueChecklist.new(
              issue_id: id,
              is_done: is_done_val,
              is_section: is_sec_val,
              subject: subj_val,
              position: idx + 1
            )
            checklist << new_item
            updated_ids << new_item.id if new_item.persisted?
          end
        end

        # Remove items that were deleted from the form
        existing_items.each do |ci|
          ci.destroy unless updated_ids.include?(ci.id)
        end

        checklist.reload
        new_checklist = checklist.collect(&:info).join("\n")

        if current_journal && create_journal && (new_checklist != old_checklist)
          current_journal.details << JournalDetail.new(
            property:  'attr',
            prop_key:  'checklist',
            old_value: old_checklist,
            value:     new_checklist
          )
        end
      end

      # Bidirectional status sync: when sub-issue status changes, sync the parent checklist item
      def sync_converted_checklist_parent_item
        return unless saved_change_to_status_id? || saved_change_to_closed_on?

        settings = RedmineIssueChecklist.settings
        sync_enabled = settings.is_a?(Hash) ? (settings[:sync_sub_issue_status].to_s != '0' && settings['sync_sub_issue_status'].to_s != '0') : true
        return unless sync_enabled

        parent_checklist_items = IssueChecklist.where(converted_issue_id: id)
        return if parent_checklist_items.empty?

        is_now_closed = closed?
        parent_checklist_items.each do |item|
          if item.is_done != is_now_closed
            item.update_columns(is_done: is_now_closed)
            item.recalc_issue_done_ratio if item.issue.present?
          end
        end
      end
    end
  end
end

unless Issue.included_modules.include?(RedmineIssueChecklist::Patches::IssuePatch)
  Issue.send(:include, RedmineIssueChecklist::Patches::IssuePatch)
end
