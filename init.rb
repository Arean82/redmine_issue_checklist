require 'redmine'
require_relative 'lib/redmine_issue_checklist'

Redmine::Plugin.register :redmine_issue_checklist do
  name 'Redmine Issue Checklist Plugin'
  author 'Arean Narrayan'
  author_url 'https://github.com/Arean82'
  description 'This plugin adds interactive checklists to Redmine issues with progress tracking and journal logging.'
  version '3.0.0'
  url 'https://github.com/Arean82/redmine_issue_checklist'
  requires_redmine version_or_higher: '5.0.0'

  settings default: {
    save_log:         false,
    issue_done_ratio: false
  }, partial: 'settings/issue_checklist'

  Redmine::AccessControl.map do |map|
    map.project_module :issue_tracking do |m|
      m.permission :view_checklists, {}
      m.permission :done_checklists, { issue_checklist: :done }
      m.permission :edit_checklists, { issue_checklist: [:delete, :done] }
    end
  end
end
