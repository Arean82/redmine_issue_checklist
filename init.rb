require 'redmine'

Redmine::Plugin.register :redmine_issue_checklist do
  name 'Redmine Issue Checklist Plugin (PRO Edition)'
  author 'Arean Narrayan'
  author_url 'https://github.com/Arean82'
  description 'Enterprise interactive issue checklist plugin with templates, categories, auto-tracker checklists, custom fields, issue query filters, change history audit trail, and email notifications.'
  version '4.0.0'
  url 'https://github.com/Arean82/redmine_issue_checklist'
  requires_redmine version_or_higher: '5.0.0'

  settings default: {
    save_log:         true,
    issue_done_ratio: false
  }, partial: 'settings/issue_checklist'

  Redmine::AccessControl.map do |map|
    map.project_module :issue_tracking do |m|
      m.permission :view_checklists, { checklists: [:show, :index] }
      m.permission :done_checklists, { issue_checklists: :done }
      m.permission :edit_checklists, { issue_checklists: [:delete, :done], checklist_templates: [:index, :new, :create, :edit, :update, :destroy] }
    end
  end

  # Menu item for checklist templates
  menu :admin_menu, :checklist_templates, { controller: 'checklist_templates', action: 'index' }, caption: :label_checklist_template_plural, html: { class: 'icon icon-checklist' }, if: Proc.new { User.current.admin? }
  menu :project_menu, :checklist_templates, { controller: 'checklist_templates', action: 'index' }, caption: :label_checklist_template_plural, param: :project_id
end

require_relative 'lib/redmine_issue_checklist'

Rails.configuration.to_prepare do
  Issue.include(RedmineIssueChecklist::Patches::IssuePatch) unless Issue.included_modules.include?(RedmineIssueChecklist::Patches::IssuePatch)
  IssuesController.include(RedmineIssueChecklist::Patches::IssuesControllerPatch) unless IssuesController.included_modules.include?(RedmineIssueChecklist::Patches::IssuesControllerPatch)
  IssueQuery.include(RedmineIssueChecklist::Patches::IssueQueryPatch) unless IssueQuery.included_modules.include?(RedmineIssueChecklist::Patches::IssueQueryPatch)
  IssuesHelper.include(RedmineIssueChecklist::Patches::IssuesHelperPatch) unless IssuesHelper.included_modules.include?(RedmineIssueChecklist::Patches::IssuesHelperPatch)
end
