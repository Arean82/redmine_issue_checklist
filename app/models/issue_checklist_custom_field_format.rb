class IssueChecklistCustomFieldFormat < Redmine::FieldFormat::Unbounded
  add 'checklist'

  self.form_partial = 'custom_fields/formats/checklist'

  def validate_custom_value(custom_value)
    []
  end

  def formatted_value(view, custom_value, options = {})
    val = custom_value.value
    return '' if val.blank?
    items = val.is_a?(Array) ? val : (YAML.safe_load(val) rescue [])
    return '' unless items.is_a?(Array)

    view.render_checklist_items_display(items)
  end

  def edit_tag(view, tag_id, tag_name, custom_value, options = {})
    val = custom_value.value
    items = val.is_a?(Array) ? val : (YAML.safe_load(val) rescue [])
    items = [] unless items.is_a?(Array)

    view.render_checklist_custom_field_edit(tag_name, items)
  end
end
