# Redmine Issue Checklist Plugin (PRO Edition)

[![Redmine 5.x / 6.x / 7.0+](https://img.shields.io/badge/Redmine-5.x%20%7C%206.x%20%7C%207.0%2B-blue.svg)](http://www.redmine.org)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](GPL.txt)

Enterprise issue checklist and task breakdown plugin for Redmine, providing template workflows, automatic tracker task population, structured checklist custom fields, issue query filters with visual progress bars, journal audit history, email notifications, sub-task assignees, due dates, per-item spent time logging, inline quick-add, interactive Markdown/TXT file import with live preview, and full REST API support.

Developed and maintained by **Arean Narrayan** ([@Arean82](https://github.com/Arean82)).

---

## Features (PRO Edition)

- **Interactive Issue Checklists**: Add, sort, toggle, and delete checklist items directly on issues with real-time UI updates.
- **Direct Inline Quick-Add**: Add checklist items and section headers directly from the issue view with assignees and due dates without opening full edit forms.
- **Per-Item Spent Time Logging**: Clock icon next to each checklist item to log spent time and activity with comments automatically referencing the task.
- **Visual Progress Bar in Issue Queries**: Displays a dynamic mini-progress bar (`completed/total` with gradient coloring) directly in the **Checklist** column on `/issues`.
- **Import from TXT / Markdown (`.md`) with Live Preview**:
  - Upload `.txt` or `.md` files.
  - Smart-detects task lines (`Item`), Markdown checkboxes (`- [ ]`, `- [x]`), and headers (`#`, `##`) into section headers.
  - Interactive preview table to toggle, review, or edit items before committing.
  - Choose between **Append** to existing list or **Replace**.
  - Works on both issue view and checklist template editor.
- **Assignees & Due Dates per Item**: Assign team members and deadlines to individual checklist tasks with overdue indicators.
- **Visual Progress Bar & Filter**: Real-time progress bar reflecting completion percentage and a quick "Hide Completed" toggle button.
- **Checklist Sections & Groups**: Group checklist items into distinct logical sections by prefixing headers with `#`.
- **Checklist Templates & Categories**: Create reusable checklist templates organized by category for project-wide or global use, with a direct 1-click category creator inside the template form.
- **Automatic Checklists by Tracker**: Designate default checklist templates for specific trackers (e.g. *Bug*, *Feature*, *QA Task*) so newly created issues automatically inherit the checklist.
- **Checklist Cloning & Export**: Quick-clone checklist items from any other issue, or export checklists directly to Markdown (`.md`).
- **REST API Endpoints**:
  - `GET /issues/:id/checklists.json` - Retrieve all checklist items (with assignees & dates).
  - `POST /issues/:id/checklists.json` - Programmatically add checklist items.
  - `PUT /issues/:id/checklists/:item_id/done.json` - Programmatically check/uncheck items.
- **Issue Query Columns & Filters**:
  - Adds a **Checklist** column in the issues list (`/issues`) displaying task progress (`completed/total`).
  - Search filter: **Checklist item contains** text search.
  - Status filter: **Checklist status** (*All items done*, *Has open items*, *Empty checklist*).
- **Change History & Audit Trail**: Full journal logging when checklist items are toggled, added, or modified.
- **Email Notifications**: Automatically dispatches notification emails to assignees and watchers on checklist changes.
- **Automatic Done Ratio**: Optionally recalculate the issue `% Done` automatically based on completed items.

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

## Configuration & Usage Manual

### 1. Permissions
Navigate to **Administration > Roles and permissions** and configure:
- `View checklist items`: Allows seeing checklists on issues.
- `Check/uncheck checklist items`: Allows marking checklist tasks done or open.
- `Edit checklist items`: Allows creating, deleting, quick-adding, importing, and managing templates.
- `Log time`: Allows logging spent time against individual checklist items.

### 2. Logging Time on Checklist Items
- Click the small clock icon next to any checklist item.
- Enter hours spent, select an activity, date, and comments.
- Submitting automatically logs the time entry to the parent issue with the task name.

### 3. Visual Progress Bar on Issues List
- Go to `/issues`, click **Options**, and add the **Checklist** column.
- The column will display an interactive visual progress bar showing completion percentage and counts (`3/7`).

### 4. Import from File with Preview
1. Click **Import from file...** (`.txt` or `.md`) on an issue or inside the template form.
2. Select your text or Markdown file.
3. Review the parsed table:
   - Header lines (`#`) are converted to **Section** headers.
   - Task lines or markdown boxes (`- [ ]`, `- [x]`) become tasks with initial state preserved.
   - Edit any line or uncheck lines you wish to omit.
   - Choose **Append to existing items** or **Replace existing items**.
4. Click **Import** to apply immediately.

---

## Author & Maintainer

- **Arean Narrayan**
- GitHub: [@Arean82](https://github.com/Arean82)
- Email: [arean@synorastudio.in](mailto:arean@synorastudio.in)

## License

This plugin is licensed under the GNU General Public License v3 (GPL-3.0). See [GPL.txt](file:///data/redmine/plugins/redmine_issue_checklist/GPL.txt) for details.
