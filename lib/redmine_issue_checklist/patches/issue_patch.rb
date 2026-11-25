module RedmineIssueChecklist
  module Patches
    module IssuePatch
      def self.included(base)
        base.class_eval do
          has_many :checklist, class_name: 'IssueChecklist', dependent: :destroy
          after_initialize :apply_tracker_default_checklist, if: :new_record?

          alias_method :copy_from_without_checklist, :copy_from
          alias_method :copy_from, :copy_from_with_checklist
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

        checklist.destroy_all
        checklist_items.each_with_index do |cli, idx|
          cli_hash = cli.respond_to?(:to_unsafe_h) ? cli.to_unsafe_h : cli.to_h
          checklist << IssueChecklist.new(
            is_done: cli_hash[:is_done] == '1' || cli_hash['is_done'] == '1' || cli_hash[:is_done] == true || cli_hash['is_done'] == true,
            is_section: cli_hash[:is_section] == '1' || cli_hash['is_section'] == '1' || cli_hash[:is_section] == true || cli_hash['is_section'] == true,
            subject: cli_hash[:subject] || cli_hash['subject'],
            position: idx + 1
          )
        end

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
    end
  end
end

unless Issue.included_modules.include?(RedmineIssueChecklist::Patches::IssuePatch)
  Issue.send(:include, RedmineIssueChecklist::Patches::IssuePatch)
end
