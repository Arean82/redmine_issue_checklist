match 'checklist/done/:checklist_item_id', to: 'issue_checklists#done', via: [:get, :post]
match 'checklist/delete/:checklist_item_id', to: 'issue_checklists#delete', via: [:get, :post]

resources :checklist_templates
resources :checklist_template_categories

resources :projects do
  resources :checklist_templates
end
