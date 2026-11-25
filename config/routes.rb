match 'checklist/done/:checklist_item_id', to: 'issue_checklists#done', via: [:get, :post]
match 'checklist/delete/:checklist_item_id', to: 'issue_checklists#delete', via: [:get, :post]
post 'issues/:issue_id/checklists/quick_add', to: 'issue_checklists#quick_add', as: 'issue_quick_add_checklist'
post 'issues/:issue_id/checklists/clone_from', to: 'issue_checklists#clone_from', as: 'issue_clone_checklist'
get  'issues/:issue_id/checklists/export', to: 'issue_checklists#export', as: 'issue_export_checklist'
post 'issues/:issue_id/checklists/batch_import', to: 'issue_checklists#batch_import', as: 'issue_batch_import_checklist'
post 'issues/:issue_id/checklists/:checklist_item_id/log_time', to: 'issue_checklists#log_time', as: 'issue_checklist_log_time'

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
