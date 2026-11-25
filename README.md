# Redmine Issue Checklist Plugin (Enterprise Edition)

[![Redmine](https://img.shields.io/badge/Redmine-5.x%20%7C%206.x%20%7C%207.x-blue.svg)](https://www.redmine.org/)
[![Ruby](https://img.shields.io/badge/Ruby-3.x%20%7C%204.x-red.svg)](https://www.ruby-lang.org/)
[![License: GPL-2.0](https://img.shields.io/badge/License-GPL--2.0-green.svg)](GPL.txt)

An industrial-strength checklist management plugin for Redmine issues. Enables teams to break down complex tasks into lightweight actionable checklist items with drag-and-drop reordering, progress-based done ratio calculations, and audit journal logging.

*Maintained and modernized by **Arean Narrayan** (<arean@synorastudio.in>)*  
*Original plugin by [Kirill Bezrukov](http://www.redminecrm.com/projects/checklist/pages/1) & [Danil Tashkinov](https://github.com/nodecarter).*

---

## 🌟 Key Features

- **Interactive Issue Checklists:** Add checklist items directly in the issue edit and show views with instantaneous AJAX toggling.
- **Drag-and-Drop Reordering:** Reorder items easily; uses native Redmine `acts_as_positioned` positioning engine (`position` scoped to `issue_id`).
- **Done Ratio Synchronization:** Optionally updates the parent issue's `% Done` based on the percentage of completed checklist items.
- **Journal Audit History:** Tracks added, completed, and removed checklist items in the issue history log.
- **Role-Based Permissions:** Granular permissions under *Issue tracking* (`view_checklists`, `done_checklists`, `edit_checklists`).
- **Rails 7, Ruby 4 & Zeitwerk Ready:** Uses `ApplicationRecord`, native `acts_as_positioned`, and `Rails.configuration.to_prepare`.

---

## 🚀 Installation

1. Clone or copy into your Redmine `plugins` directory:
   ```bash
   cd /data/redmine/plugins
   git clone https://github.com/Arean82/redmine_issue_checklist.git
   ```

2. Run plugin database migrations:
   ```bash
   RAILS_ENV=production bin/rails redmine:plugins:migrate
   ```

3. Restart your Redmine application server:
   ```bash
   sudo systemctl restart redmine
   ```

4. Configure options under **Administration -> Plugins -> Redmine Issue Checklist Plugin -> Configure**.

---

## 👤 Author & Support

- **Author & Maintainer:** Arean Narrayan  
- **Email:** [arean@synorastudio.in](mailto:arean@synorastudio.in)  
- **GitHub:** [@Arean82](https://github.com/Arean82)  
- **Repository:** [https://github.com/Arean82/redmine_issue_checklist](https://github.com/Arean82/redmine_issue_checklist)

---

## 📄 License

Distributed under the **GNU General Public License v2 (GPL-2.0)**.  
Copyright (c) 2011–2018 Kirill Bezrukov, Danil Tashkinov. Copyright (c) 2024–2026 Arean Narrayan (<arean@synorastudio.in>).
