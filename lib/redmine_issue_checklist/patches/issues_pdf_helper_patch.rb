module RedmineIssueChecklist
  module Patches
    module IssuesPdfHelperPatch
      def self.included(base)
        base.class_eval do
          alias_method :issue_to_pdf_without_checklist, :issue_to_pdf
          alias_method :issue_to_pdf, :issue_to_pdf_with_checklist
        end
      end

      def issue_to_pdf_with_checklist(issue, assoc = {})
        pdf = issue_to_pdf_without_checklist(issue, assoc)

        settings = RedmineIssueChecklist.settings
        format_pdf = settings.is_a?(Hash) ? (settings[:format_checklist_in_pdf].to_s != '0' && settings['format_checklist_in_pdf'].to_s != '0') : true
        return pdf unless format_pdf
        return pdf unless issue.checklist.any? && User.current.allowed_to?(:view_checklists, issue.project)

        pdf.SetFontStyle('B', 9)
        pdf.RDMCell(190, 5, l(:label_issue_checklist_plural) + ":", "LTR")
        pdf.ln

        issue.checklist.each do |item|
          pdf.SetFontStyle('', 8)
          if item.is_section
            pdf.SetFontStyle('B', 8)
            pdf.RDMCell(190, 5, "--- #{item.subject.strip} ---", "LR")
          else
            mark = item.is_done? ? "[X]" : "[ ]"
            text = "  #{mark} #{item.subject.strip}"
            text += " (#{l(:field_assigned_to)}: #{item.assigned_to.name})" if item.assigned_to.present?
            text += " (#{l(:field_due_date)}: #{item.due_date})" if item.due_date.present?
            text += " [##{item.converted_issue_id}]" if item.converted_issue_id.present?
            pdf.RDMCell(190, 5, text, "LR")
          end
          pdf.ln
        end

        pdf.RDMCell(190, 2, "", "T")
        pdf.ln
        pdf
      end
    end
  end
end

unless Redmine::Export::PDF::IssuesPdfHelper.included_modules.include?(RedmineIssueChecklist::Patches::IssuesPdfHelperPatch)
  Redmine::Export::PDF::IssuesPdfHelper.send(:include, RedmineIssueChecklist::Patches::IssuesPdfHelperPatch)
end
