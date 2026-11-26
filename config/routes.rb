match 'checklist/done/:checklist_item_id', to: 'issue_checklists#done', via: [:get, :post]
match 'checklist/delete/:checklist_item_id', to: 'issue_checklists#delete', via: [:get, :post]
post 'issues/:issue_id/checklists/quick_add', to: 'issue_checklists#quick_add', as: 'issue_quick_add_checklist'
post 'issues/:issue_id/checklists/clone_from', to: 'issue_checklists#clone_from', as: 'issue_clone_checklist'
get  'issues/:issue_id/checklists/export', to: 'issue_checklists#export', as: 'issue_export_checklist'
post 'issues/:issue_id/checklists/batch_import', to: 'issue_checklists#batch_import', as: 'issue_batch_import_checklist'
post 'issues/:issue_id/checklists/:checklist_item_id/log_time', to: 'issue_checklists#log_time', as: 'issue_checklist_log_time'
post 'issues/:issue_id/checklists/:checklist_item_id/convert_to_issue', to: 'issue_checklists#convert_to_issue', as: 'issue_checklist_convert_to_issue'

# Standalone daily / personal checklist endpoints for My Page
post 'my/checklists/quick_add', to: 'issue_checklists#my_quick_add', as: 'my_checklist_quick_add'
post 'my/checklists/:checklist_item_id/done', to: 'issue_checklists#my_done', as: 'my_checklist_done'
delete 'my/checklists/:checklist_item_id', to: 'issue_checklists#my_delete', as: 'my_checklist_delete'

resources :issues do
  resources :issue_checklists, path: 'checklists', only: [:index, :create, :show, :update, :destroy] do
    member do
      put :done
    end
  end
end

resources :checklist_templates
resources :checklist_template_categories

resources :projects do
  resources :checklist_templates
end
