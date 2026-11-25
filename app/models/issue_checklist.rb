class IssueChecklist < ApplicationRecord
  belongs_to :issue
  belongs_to :author, class_name: 'User', foreign_key: 'author_id', optional: true
  belongs_to :assigned_to, class_name: 'Principal', foreign_key: 'assigned_to_id', optional: true
  has_one :comment, as: :commented, dependent: :delete
  acts_as_positioned scope: :issue_id

  validates_presence_of :subject

  def editable_by?(usr = User.current)
    usr && (usr.allowed_to?(:edit_checklists, project) || (self.author == usr && usr.allowed_to?(:edit_own_checklists, project)))
  end

  def project
    self.issue.project if self.issue
  end

  def info
    parts = []
    if is_section
      parts << "# #{self.subject.strip}"
    else
      parts << "[#{self.is_done ? 'x' : ' '}] #{self.subject.strip}"
    end
    parts << "(Assignee: #{assigned_to.name})" if assigned_to.present?
    parts << "(Due: #{due_date.to_s})" if due_date.present?
    parts.join(' ')
  end

  def recalc_issue_done_ratio
    return false if (Setting.issue_done_ratio != 'issue_field') || !RedmineIssueChecklist.settings[:issue_done_ratio]
    items = issue.checklist.reject(&:is_section)
    return false if items.empty?
    done_checklist   = items.map { |c| c.is_done ? 1 : 0 }
    issue.done_ratio = (done_checklist.count(1) * 10) / done_checklist.count * 10
    issue.save
  end
end
