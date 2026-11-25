module RedmineIssueChecklist
  module Patches
    module IssuesHelperPatch
      def details_to_strings(details, no_html = false, options = {})
        details_checklist, details_other = details.partition { |x| x.prop_key == 'checklist' }

        if @issue.nil? || !User.current.allowed_to?(:view_checklists, @issue.project, global: @issue.present?)
          return super(details_other, no_html, options)
        end

        strings = details_checklist.map do |detail|
          item_label = l(:label_issue_checklist_plural)
          old_v = detail.old_value.to_s
          new_v = detail.value.to_s

          if no_html
            "#{item_label}: #{old_v} -> #{new_v}"
          else
            "<strong>#{ERB::Util.html_escape(item_label)}</strong>: " \
            "<span class='checklist-history-old'>#{ERB::Util.html_escape(old_v)}</span> &rarr; " \
            "<span class='checklist-history-new'>#{ERB::Util.html_escape(new_v)}</span>".html_safe
          end
        end

        strings + super(details_other, no_html, options)
      end
    end
  end
end
