# frozen_string_literal: true

module RedmineIssueChecklist
  module Hooks
    class ModelIssueHook < Redmine::Hook::ViewListener
      def controller_issues_edit_before_save(context = {})
        if User.current.allowed_to?(:edit_checklists, context[:issue].project)
          save_checklist_to_issue(context, RedmineIssueChecklist.settings[:save_log])
        end
      end

      def controller_issues_new_after_save(context = {})
        if User.current.allowed_to?(:edit_checklists, context[:issue].project)
          save_checklist_to_issue(context, false)
        end
      end

      def save_checklist_to_issue(context, create_journal)
        issue = context[:issue]
        checklist_items = context[:params] && context[:params][:check_list_items]
        issue.update_checklist_items(checklist_items, create_journal) if issue && checklist_items
      end
    end
  end
end
