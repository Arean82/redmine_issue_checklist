class ChecklistTemplate < ApplicationRecord
  belongs_to :project, optional: true
  belongs_to :category, class_name: 'ChecklistTemplateCategory', foreign_key: 'category_id', optional: true
  belongs_to :user, optional: true
  belongs_to :tracker, optional: true

  # Rails 7.1+ uses `coder: YAML`; Rails 6.x / Redmine 5 uses `serialize :col, YAML`
  if Rails::VERSION::MAJOR >= 7 && Rails::VERSION::MINOR >= 1
    serialize :template_items, coder: YAML
  else
    serialize :template_items, YAML
  end

  validates :name, presence: true

  scope :public_templates, -> { where(is_public: true) }
  scope :for_project, ->(project) { where('project_id IS NULL OR project_id = ?', project.is_a?(Project) ? project.id : project) }
  scope :for_tracker, ->(tracker) { where(tracker_id: tracker.is_a?(Tracker) ? tracker.id : tracker) }
  scope :default_templates, -> { where(is_default: true) }

  def items
    case template_items
    when Array
      template_items
    when String
      template_items.split("\n").map(&:strip).reject(&:empty?).map do |line|
        { 'is_done' => false, 'is_section' => line.start_with?('#'), 'subject' => line.delete_prefix('#').strip }
      end
    else
      []
    end
  end

  def items=(val)
    self.template_items = val
  end

  def to_s
    name
  end
end
