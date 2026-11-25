# Redmine Issue Checklist Plugin (PRO Edition)

[![Redmine 5.x / 6.x / 7.0+](https://img.shields.io/badge/Redmine-5.x%20%7C%206.x%20%7C%207.0%2B-blue.svg)](http://www.redmine.org)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](GPL.txt)

Interactive, enterprise-grade checklist management for Redmine issues with template workflows, tracker automation, custom fields, query filtering, audit logging, and email notification delivery.

Developed and maintained by **Arean Narrayan** ([@Arean82](https://github.com/Arean82)).

---

## Features (PRO Edition)

- **Interactive Issue Checklists**: Add, sort, toggle, and delete checklist items directly on issues with real-time UI updates.
- **Checklist Sections & Groups**: Group checklist items into distinct logical sections by prefixing headers with `#`.
- **Checklist Templates & Categories**: Create reusable checklist templates organized by category for project-wide or global use.
- **Automatic Checklists by Tracker**: Designate default checklist templates for specific trackers (e.g. *Bug*, *Feature*, *QA Task*) so newly created issues automatically inherit the checklist.
- **Checklist Custom Field**: Native checklist custom field support (`IssueChecklistCustomFieldFormat`) for structured forms.
- **Issue Query Columns & Filters**:
  - Adds a **Checklist** column in the issues list (`/issues`) displaying task progress (`completed/total`).
  - Search filter: **Checklist item contains** text search.
  - Status filter: **Checklist status** (*All items done*, *Has open items*, *Empty checklist*).
- **Change History & Audit Trail**: Full journal logging when checklist items are toggled, added, or modified.
- **Email Notifications**: Automatically dispatches notification emails to assignees and watchers on checklist changes.
- **Automatic Done Ratio**: Optionally recalculate the issue `% Done` automatically based on completed items.
- **Import/Export**: Drag-and-drop or select plain-text files to batch-import checklist lines.

---

## Compatibility

- Redmine 5.0+, 6.0+, and 7.0+
- Ruby 3.2+ / 4.0+
- Rails 7.x / 8.x (Zeitwerk autoloading compliant)
- PostgreSQL, MySQL, SQLite3

---

## Installation

1. Clone the repository into your Redmine `plugins` directory:
   ```bash
   cd /data/redmine/plugins
   git clone https://github.com/Arean82/redmine_issue_checklist.git
   ```

2. Run plugin database migrations:
   ```bash
   bundle exec rake redmine:plugins:migrate RAILS_ENV=production
   ```

3. Restart your Redmine application:
   ```bash
   sudo systemctl restart redmine
   # or
   touch tmp/restart.txt
   ```

---

## Configuration & Usage

### 1. Permissions
Navigate to **Administration > Roles and permissions** and configure:
- `View checklist items`
- `Check/uncheck checklist items`
- `Edit checklist items`

### 2. Checklist Templates & Categories
- **Global Management**: Go to **Administration > Checklist Templates** (or **Checklist Categories**).
- **Project-Level**: Open the project tab **Checklist Templates** to configure project-scoped templates.
- **Tracker Default**: Check **Default** and pick a **Tracker** (e.g. *Bug*) to automatically populate newly created issues of that tracker.

### 3. Issue Filters & Columns
- In the issues list (`/issues`), click **Options** and add **Checklist** to the selected columns.
- Under **Add filter**, select **Checklist status** or **Checklist item contains**.

---

## Author & Maintainer

- **Arean Narrayan**
- GitHub: [@Arean82](https://github.com/Arean82)
- Email: [arean@synorastudio.in](mailto:arean@synorastudio.in)

## License

This plugin is licensed under the GNU General Public License v3 (GPL-3.0). See [GPL.txt](file:///data/redmine/plugins/redmine_issue_checklist/GPL.txt) for details.
