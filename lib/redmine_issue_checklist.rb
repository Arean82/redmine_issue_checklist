module RedmineIssueChecklist
  def self.settings
    Setting[:plugin_redmine_issue_checklist].blank? ? {} : Setting[:plugin_redmine_issue_checklist]
  end
end

require_relative 'redmine_issue_checklist/hooks/views_issues_hook'
require_relative 'redmine_issue_checklist/hooks/model_issue_hook'
require_relative 'redmine_issue_checklist/patches/issue_patch'
require_relative 'redmine_issue_checklist/patches/issues_controller_patch'
require_relative 'redmine_issue_checklist/patches/issue_query_patch'
require_relative 'redmine_issue_checklist/patches/issues_helper_patch'

Rails.configuration.to_prepare do
  Issue.include(RedmineIssueChecklist::Patches::IssuePatch) unless Issue.included_modules.include?(RedmineIssueChecklist::Patches::IssuePatch)
  IssuesController.include(RedmineIssueChecklist::Patches::IssuesControllerPatch) unless IssuesController.included_modules.include?(RedmineIssueChecklist::Patches::IssuesControllerPatch)
  IssueQuery.include(RedmineIssueChecklist::Patches::IssueQueryPatch) unless IssueQuery.included_modules.include?(RedmineIssueChecklist::Patches::IssueQueryPatch)
  IssuesHelper.include(RedmineIssueChecklist::Patches::IssuesHelperPatch) unless IssuesHelper.included_modules.include?(RedmineIssueChecklist::Patches::IssuesHelperPatch)
end
