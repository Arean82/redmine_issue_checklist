class IssueChecklistsController < ApplicationController
  before_action :find_checklist_item, only: [:done, :delete, :update, :destroy, :log_time]
  before_action :find_issue, only: [:quick_add, :clone_from, :export, :batch_import, :log_time, :index, :create]

  accept_api_auth :index, :create, :show, :update, :destroy, :done

  def index
    (render_403; return false) unless User.current.allowed_to?(:view_checklists, @project)

    respond_to do |format|
      format.json do
        render json: @issue.checklist.as_json(
          only: [:id, :subject, :is_done, :is_section, :position, :assigned_to_id, :due_date],
          include: { assigned_to: { only: [:id, :name] } }
        )
      end
      format.xml do
        render xml: @issue.checklist.to_xml(
          only: [:id, :subject, :is_done, :is_section, :position, :assigned_to_id, :due_date]
        )
      end
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

      if RedmineIssueChecklist.settings[:save_log] && @item.persisted?
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
    @project        = @checklist_item.issue.project
  end

  def find_issue
    @issue = Issue.find(params[:issue_id])
    @project = @issue.project
  end
end
