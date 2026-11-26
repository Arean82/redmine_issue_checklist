class IssueChecklist < ApplicationRecord
  belongs_to :issue, optional: true
  belongs_to :user, optional: true
  belongs_to :author, class_name: 'User', foreign_key: 'author_id', optional: true
  belongs_to :assigned_to, class_name: 'Principal', foreign_key: 'assigned_to_id', optional: true
  belongs_to :converted_issue, class_name: 'Issue', foreign_key: 'converted_issue_id', optional: true
  has_one :comment, as: :commented, dependent: :delete
  acts_as_positioned scope: :issue_id

  validates_presence_of :subject

  scope :daily_routines, -> { where(is_daily: true) }
  scope :for_user_or_team, ->(usr) {
    team_ids = usr.group_ids
    where('issue_checklists.user_id = :uid OR issue_checklists.assigned_to_id = :uid OR issue_checklists.assigned_to_id IN (:gids)', uid: usr.id, gids: team_ids.presence || [0])
  }

  def editable_by?(usr = User.current)
    return true if usr.admin?
    if project.present?
      usr && (usr.allowed_to?(:edit_checklists, project) || (self.author == usr && usr.allowed_to?(:edit_own_checklists, project)))
    else
      user_id == usr.id || author_id == usr.id || assigned_to_id == usr.id || usr.is_or_belongs_to?(assigned_to)
    end
  end

  def project
    self.issue.project if self.issue.present?
  end

  # Daily recurring uncheck logic: if marked daily and done on a previous date, reset is_done to false
  def check_daily_reset!
    if is_daily? && is_done? && last_done_date.present? && last_done_date < Date.today
      update_columns(is_done: false, last_done_date: nil)
      self.is_done = false
    end
  end

  def info
    parts = []
    if converted_issue.present?
      parts << "[##{converted_issue.id} #{converted_issue.subject}]"
    elsif is_section
      parts << "# #{self.subject.strip}"
    else
      parts << "[#{self.is_done ? 'x' : ' '}] #{self.subject.strip}"
    end
    parts << "(Assignee: #{assigned_to.name})" if assigned_to.present?
    parts << "(Due: #{due_date.to_s})" if due_date.present?
    parts << "[Daily]" if is_daily?
    parts.join(' ')
  end

  def recalc_issue_done_ratio
    return false unless issue.present?
    return false if (Setting.issue_done_ratio != 'issue_field') || !RedmineIssueChecklist.settings[:issue_done_ratio]
    items = issue.checklist.reject(&:is_section)
    return false if items.empty?
    done_checklist   = items.map { |c| c.is_done ? 1 : 0 }
    issue.done_ratio = (done_checklist.count(1) * 10) / done_checklist.count * 10
    issue.save
  end
end
