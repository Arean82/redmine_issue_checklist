class ChecklistTemplateCategoriesController < ApplicationController
  layout 'admin'
  menu_item :checklist_templates

  before_action :require_admin
  before_action :find_category, only: [:edit, :update, :destroy]

  def index
    @categories = ChecklistTemplateCategory.order(:position)
  end

  def new
    @category = ChecklistTemplateCategory.new
  end

  def create
    @category = ChecklistTemplateCategory.new(category_params)
    if @category.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to checklist_template_categories_path
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @category.update(category_params)
      flash[:notice] = l(:notice_successful_update)
      redirect_to checklist_template_categories_path
    else
      render :edit
    end
  end

  def destroy
    @category.destroy
    flash[:notice] = l(:notice_successful_delete)
    redirect_to checklist_template_categories_path
  end

  private

  def find_category
    @category = ChecklistTemplateCategory.find(params[:id])
  end

  def category_params
    params.require(:checklist_template_category).permit(:name, :position)
  end
end
