namespace :redmine do
  namespace :issue_checklist do
    desc 'Reset daily recurring checklists that were completed prior to today'
    task reset_daily_routines: :environment do
      puts "[#{Time.now}] Starting reset of daily recurring checklists..."
      
      count = 0
      IssueChecklist.daily_routines.where(is_done: true).where('last_done_date < ?', Date.today).find_each do |item|
        item.update_columns(is_done: false, last_done_date: nil)
        count += 1
      end

      puts "[#{Time.now}] Successfully reset #{count} daily checklist item(s)."
    end
  end
end
