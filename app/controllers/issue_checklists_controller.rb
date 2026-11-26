class IssueChecklistsController < ApplicationController
  before_action :find_checklist_item, only: [:done, :delete, :update, :destroy, :log_time, :convert_to_issue, :my_done, :my_delete]
  before_action :find_issue, only: [:quick_add, :clone_from, :export, :batch_import, :log_time, :convert_to_issue, :index, :create]

  accept_api_auth :index, :create, :show, :update, :destroy, :done

  def index
    (render_403; return false) unless User.current.allowed_to?(:view_checklists, @project)

    respond_to do |format|
      format.json do
        render json: @issue.checklist.as_json(
          only: [:id, :subject, :is_done, :is_section, :position, :assigned_to_id, :due_date, :converted_issue_id],
          include: { assigned_to: { only: [:id, :name] } }
        )
      end
      format.xml do
        render xml: @issue.checklist.to_xml(
          only: [:id, :subject, :is_done, :is_section, :position, :assigned_to_id, :due_date, :converted_issue_id]
        )
      end
    end
  end

  def convert_to_issue
    (render_403; return false) unless User.current.allowed_to?(:add_issues, @project)

    child_issue = Issue.new(
      project: @project,
      tracker: @issue.tracker,
      category: @issue.category,
      fixed_version: @issue.fixed_version,
      priority: @issue.priority,
      author: User.current,
      parent_id: @issue.id,
      subject: @checklist_item.subject.strip,
      description: "Promoted from checklist on issue ##{@issue.id}",
      assigned_to_id: @checklist_item.assigned_to_id || @issue.assigned_to_id,
      due_date: @checklist_item.due_date
    )

    if child_issue.save
      @checklist_item.update(converted_issue_id: child_issue.id, is_done: true)

      if RedmineIssueChecklist.settings[:save_log]
        journal = @issue.init_journal(User.current)
        journal.details << JournalDetail.new(
          property: 'attr',
          prop_key: 'checklist',
          old_value: @checklist_item.subject,
          value: "[##{child_issue.id} #{child_issue.subject}]"
        )
        journal.notes = l(:notice_checklist_converted_journal_note, id: child_issue.id, subject: child_issue.subject)
        journal.save
      end

      flash[:notice] = l(:notice_checklist_converted_successfully, id: child_issue.id)
    else
      flash[:error] = child_issue.errors.full_messages.join(', ')
    end

    respond_to do |format|
      format.js
      format.html { redirect_to issue_path(@issue) }
    end
  end

  # Standalone My Page endpoints
  def my_quick_add
    subject = params[:subject].to_s.strip
    if subject.present?
      assigned_to_id = params[:assigned_to_id].presence || User.current.id
      is_daily = params[:is_daily] == '1'
      is_sec = params[:is_section] == '1' || subject.start_with?('#')
      clean_subject = subject.delete_prefix('#').strip

      @item = IssueChecklist.create(
        user_id: User.current.id,
        author_id: User.current.id,
        assigned_to_id: assigned_to_id,
        subject: clean_subject,
        is_section: is_sec,
        is_daily: is_daily,
        is_done: false,
        due_date: params[:due_date].presence
      )
    end

    respond_to do |format|
      format.js
      format.html { redirect_to my_page_path }
    end
  end

  def my_done
    (render_403; return false) unless @checklist_item.editable_by?(User.current)

    @checklist_item.is_done = !@checklist_item.is_done
    @checklist_item.last_done_date = @checklist_item.is_done ? Date.today : nil
    @checklist_item.save

    respond_to do |format|
      format.js
      format.html { redirect_to my_page_path }
    end
  end

  def my_delete
    (render_403; return false) unless @checklist_item.editable_by?(User.current)

    @checklist_item.destroy
    respond_to do |format|
      format.js
      format.html { redirect_to my_page_path }
    end
  end

  def log_time
    (render_403; return false) unless User.current.allowed_to?(:log_time, @project)

    hours = params[:hours].to_f
    if hours > 0
      comments = params[:comments].presence || "Checklist: #{@checklist_item.subject.strip}"
      activity_id = params[:activity_id] || TimeEntryActivity.shared.active.first&.id

      time_entry = TimeEntry.new(
        project: @project,
        issue: @issue,
        user: User.current,
        spent_on: params[:spent_on] || Date.today,
        hours: hours,
        activity_id: activity_id,
        comments: comments
      )

      if time_entry.save
        flash[:notice] = l(:notice_time_logged_successfully, hours: hours)
      else
        flash[:error] = time_entry.errors.full_messages.join(', ')
      end
    else
      flash[:error] = l(:error_invalid_spent_hours)
    end

    respond_to do |format|
      format.js
      format.html { redirect_to issue_path(@issue) }
    end
  end

  def batch_import
    (render_403; return false) unless User.current.allowed_to?(:edit_checklists, @project)

    mode = params[:mode] || 'append'
    raw_items = params[:items] || []

    old_info = @issue.checklist.collect(&:info).join("\n")

    if mode == 'replace'
      @issue.checklist.destroy_all
      base_pos = 0
    else
      base_pos = @issue.checklist.count
    end

    raw_items.each_with_index do |it, idx|
      it_hash = it.respond_to?(:to_unsafe_h) ? it.to_unsafe_h : it.to_h
      subject = it_hash[:subject] || it_hash['subject']
      next if subject.blank?

      is_sec = it_hash[:is_section] == '1' || it_hash['is_section'] == '1' || it_hash[:is_section] == true || it_hash['is_section'] == true
      is_dn = it_hash[:is_done] == '1' || it_hash['is_done'] == '1' || it_hash[:is_done] == true || it_hash['is_done'] == true

      @issue.checklist.create(
        subject: subject,
        is_section: is_sec,
        is_done: is_dn,
        position: base_pos + idx + 1
      )
    end

    if RedmineIssueChecklist.settings[:save_log]
      new_info = @issue.checklist.collect(&:info).join("\n")
      journal = @issue.init_journal(User.current)
      journal.details << JournalDetail.new(
        property: 'attr',
        prop_key: 'checklist',
        old_value: old_info,
        value: new_info
      )
      journal.save
      @issue.reload
      Mailer.deliver_issue_edit(journal) if Setting.notified_events.include?('issue_updated')
    end

    respond_to do |format|
      format.json { render json: { success: true, count: @issue.checklist.count } }
      format.html { redirect_to issue_path(@issue) }
    end
  end

  def create
    (render_403; return false) unless User.current.allowed_to?(:edit_checklists, @project)

    checklist_params = params[:checklist] || params
    subject = checklist_params[:subject]
    is_section = checklist_params[:is_section] == '1' || checklist_params[:is_section] == true
    assigned_to_id = checklist_params[:assigned_to_id]
    due_date = checklist_params[:due_date]

    item = @issue.checklist.build(
      subject: subject,
      is_section: is_section,
      is_done: false,
      assigned_to_id: assigned_to_id.presence,
      due_date: due_date.presence,
      position: @issue.checklist.count + 1
    )

    if item.save
      if RedmineIssueChecklist.settings[:save_log]
        journal = @issue.init_journal(User.current)
        journal.details << JournalDetail.new(property: 'attr', prop_key: 'checklist', old_value: '', value: item.info)
        journal.save
      end

      respond_to do |format|
        format.json { render json: item.as_json(only: [:id, :subject, :is_done, :is_section, :position, :assigned_to_id, :due_date]), status: :created }
        format.xml  { render xml: item.to_xml, status: :created }
      end
    else
      respond_to do |format|
        format.json { render json: { errors: item.errors.full_messages }, status: :unprocessable_entity }
        format.xml  { render xml: item.errors, status: :unprocessable_entity }
      end
    end
  end

  def quick_add
    (render_403; return false) unless User.current.allowed_to?(:edit_checklists, @project)

    subject = params[:subject].to_s.strip
    if subject.present?
      # Check if user requested creating a sub-issue directly
      if params[:create_mode] == 'sub_issue' && User.current.allowed_to?(:add_issues, @project)
        child = Issue.new(
          project: @project,
          tracker: @issue.tracker,
          category: @issue.category,
          fixed_version: @issue.fixed_version,
          priority: @issue.priority,
          author: User.current,
          parent_id: @issue.id,
          subject: subject,
          assigned_to_id: params[:assigned_to_id].presence || @issue.assigned_to_id,
          due_date: params[:due_date].presence
        )
        if child.save
          @item = @issue.checklist.create(
            subject: subject,
            is_section: false,
            is_done: true,
            converted_issue_id: child.id,
            position: @issue.checklist.count + 1
          )
        end
      else
        is_section = params[:is_section] == '1' || subject.start_with?('#')
        clean_subject = subject.delete_prefix('#').strip

        @item = @issue.checklist.create(
          subject: clean_subject,
          is_section: is_section,
          is_done: false,
          assigned_to_id: params[:assigned_to_id].presence,
          due_date: params[:due_date].presence,
          position: @issue.checklist.count + 1
        )
      end

      if RedmineIssueChecklist.settings[:save_log] && @item && @item.persisted?
        journal = @issue.init_journal(User.current)
        journal.details << JournalDetail.new(
          property: 'attr',
          prop_key: 'checklist',
          old_value: '',
          value: @item.info
        )
        journal.save
        @issue.reload
        Mailer.deliver_issue_edit(journal) if Setting.notified_events.include?('issue_updated')
      end
    end

    respond_to do |format|
      format.js
      format.html { redirect_to issue_path(@issue) }
    end
  end

  def clone_from
    (render_403; return false) unless User.current.allowed_to?(:edit_checklists, @project)

    source_issue = Issue.visible.find_by(id: params[:source_issue_id])
    if source_issue && source_issue.checklist.any?
      old_info = @issue.checklist.collect(&:info).join("\n")
      current_pos = @issue.checklist.count

      source_issue.checklist.each_with_index do |src_item, idx|
        @issue.checklist.create(
          subject: src_item.subject,
          is_section: src_item.is_section,
          is_done: false,
          assigned_to_id: src_item.assigned_to_id,
          position: current_pos + idx + 1
        )
      end

      if RedmineIssueChecklist.settings[:save_log]
        new_info = @issue.checklist.collect(&:info).join("\n")
        journal = @issue.init_journal(User.current)
        journal.details << JournalDetail.new(property: 'attr', prop_key: 'checklist', old_value: old_info, value: new_info)
        journal.save
      end

      flash[:notice] = l(:notice_checklist_cloned_successfully)
    else
      flash[:error] = l(:error_no_checklist_to_clone)
    end

    redirect_to issue_path(@issue)
  end

  def export
    (render_403; return false) unless User.current.allowed_to?(:view_checklists, @project)

    lines = []
    lines << "# Checklist for Issue ##{@issue.id}: #{@issue.subject}"
    lines << ""
    @issue.checklist.each do |item|
      lines << item.info
    end

    send_data lines.join("\n"),
              filename: "issue-#{@issue.id}-checklist.md",
              type: 'text/markdown; charset=utf-8'
  end

  def done
    (render_403; return false) unless User.current.allowed_to?(:done_checklists, @checklist_item.issue.project)

    old_checklist_item      = @checklist_item.dup
    @checklist_item.is_done = !@checklist_item.is_done

    if @checklist_item.save
      if RedmineIssueChecklist.settings[:save_log] && old_checklist_item.info != @checklist_item.info
        journal = @checklist_item.issue.init_journal(User.current)
        journal.details << JournalDetail.new(
          property: 'attr',
          prop_key: 'checklist',
          old_value: old_checklist_item.info,
          value:    @checklist_item.info
        )
        journal.save
        @checklist_item.issue.reload
        Mailer.deliver_issue_edit(journal) if Setting.notified_events.include?('issue_updated')
      end

      if (Setting.issue_done_ratio == 'issue_field') && RedmineIssueChecklist.settings[:issue_done_ratio]
        items = @checklist_item.issue.checklist.reject(&:is_section)
        if items.any?
          done_checklist = items.map { |c| c.is_done ? 1 : 0 }
          @checklist_item.issue.done_ratio = (done_checklist.count(1) * 10) / done_checklist.count * 10
          @checklist_item.issue.save
        end
      end
    end

    respond_to do |format|
      format.js
      format.json { render json: @checklist_item.as_json(only: [:id, :subject, :is_done, :is_section, :position, :assigned_to_id, :due_date]) }
      format.html { redirect_back(fallback_location: root_path) }
    end
  end

  def delete
    (render_403; return false) unless User.current.allowed_to?(:edit_checklists, @checklist_item.issue.project)

    @checklist_item.destroy
    respond_to do |format|
      format.js do
        render js: "$('#checklist_item_#{@checklist_item.id}').fadeOut(300, function(){ $(this).remove(); updateChecklistProgress(); });"
      end
      format.json { head :no_content }
      format.html { redirect_back(fallback_location: root_path) }
    end
  end

  private

  def find_checklist_item
    @checklist_item = IssueChecklist.find(params[:id] || params[:checklist_item_id])
    @project        = @checklist_item.issue.project if @checklist_item.issue.present?
  end

  def find_issue
    @issue = Issue.find(params[:issue_id])
    @project = @issue.project
  end
end
