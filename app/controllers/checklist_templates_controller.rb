class ChecklistTemplatesController < ApplicationController
  layout :determine_layout
  menu_item :checklist_templates

  before_action :find_project, only: [:index, :new, :create]
  before_action :find_template, only: [:edit, :update, :destroy]

  def index
    @templates = ChecklistTemplate.all
    @templates = @templates.for_project(@project) if @project
    @categories = ChecklistTemplateCategory.order(:position)

    if params[:category_id].present?
      @selected_category_id = params[:category_id].to_s
      @templates = @templates.where(category_id: @selected_category_id)
    end

    respond_to do |format|
      format.html
      format.json { render json: @templates.to_json(methods: :items) }
    end
  end

  def new
    @template = ChecklistTemplate.new(project: @project)
    @categories = ChecklistTemplateCategory.order(:position)
  end

  def create
    @template = ChecklistTemplate.new(template_params)
    @template.project = @project if @project
    @template.user = User.current

    if @template.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to project_checklist_templates_path_or_default
    else
      @categories = ChecklistTemplateCategory.order(:position)
      render :new
    end
  end

  def edit
    @categories = ChecklistTemplateCategory.order(:position)
  end

  def update
    if @template.update(template_params)
      flash[:notice] = l(:notice_successful_update)
      redirect_to project_checklist_templates_path_or_default
    else
      @categories = ChecklistTemplateCategory.order(:position)
      render :edit
    end
  end

  def destroy
    @template.destroy
    flash[:notice] = l(:notice_successful_delete)
    redirect_to project_checklist_templates_path_or_default
  end

  private

  def find_project
    @project = Project.find(params[:project_id]) if params[:project_id].present?
  end

  def find_template
    @template = ChecklistTemplate.find(params[:id])
    @project = @template.project
  end

  def template_params
    params.require(:checklist_template).permit(
      :name, :category_id, :is_public, :is_default, :tracker_id, :template_items
    )
  end

  def project_checklist_templates_path_or_default
    if @project
      project_checklist_templates_path(@project)
    else
      checklist_templates_path
    end
  end

  def determine_layout
    @project ? 'base' : 'admin'
  end
end
