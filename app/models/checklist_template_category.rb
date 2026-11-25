class ChecklistTemplateCategory < ApplicationRecord
  acts_as_positioned

  has_many :checklist_templates, foreign_key: 'category_id', dependent: :nullify

  validates :name, presence: true, uniqueness: true

  def to_s
    name
  end
end
