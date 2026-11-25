require File.expand_path('../../test_helper', __FILE__)

class ChecklistTemplateTest < ActiveSupport::TestCase
  fixtures :projects, :users, :trackers

  def test_template_creation_and_scoping
    cat = ChecklistTemplateCategory.create!(name: 'QA & Testing')
    tpl = ChecklistTemplate.create!(
      name: 'Sprint Sanity Check',
      category: cat,
      is_public: true,
      template_items: "Check 1\nCheck 2"
    )

    assert_equal cat, tpl.category
    assert_includes ChecklistTemplate.public_templates, tpl
  end

  def test_category_ordering
    cat1 = ChecklistTemplateCategory.create!(name: 'Cat A', position: 2)
    cat2 = ChecklistTemplateCategory.create!(name: 'Cat B', position: 1)
    cats = ChecklistTemplateCategory.order(:position)
    assert_equal cat2, cats.first
  end
end
