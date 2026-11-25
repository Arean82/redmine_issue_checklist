# Redmine Issue Checklist Plugin (PRO Edition)

[![Redmine 5.x / 6.x / 7.0+](https://img.shields.io/badge/Redmine-5.x%20%7C%206.x%20%7C%207.0%2B-blue.svg)](http://www.redmine.org)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](GPL.txt)

Enterprise issue checklist and task breakdown plugin for Redmine, providing template workflows, automatic tracker task population, structured checklist custom fields, issue query filters, journal audit history, email notifications, sub-task assignees, due dates, inline quick-add, and full REST API support.

Developed and maintained by **Arean Narrayan** ([@Arean82](https://github.com/Arean82)).

---

## Features (PRO Edition)

- **Interactive Issue Checklists**: Add, sort, toggle, and delete checklist items directly on issues with real-time UI updates.
- **Direct Inline Quick-Add**: Add checklist items and section headers directly from the issue view with assignees and due dates without opening full edit forms.
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

## Configuration & Usage Manual

### 1. Permissions
Navigate to **Administration > Roles and permissions** and configure:
- `View checklist items`: Allows seeing checklists on issues.
- `Check/uncheck checklist items`: Allows marking checklist tasks done or open.
- `Edit checklist items`: Allows creating, deleting, quick-adding, and managing templates.

### 2. Checklist Templates & Categories
- **Global Management**: Go to **Administration > Checklist Templates** (or **Checklist Categories**).
- **Project-Level**: Open any project's **Checklist Templates** tab to configure project-scoped templates.
- **Creating a Template**:
  - **Name**: Name of the checklist template.
  - **Category**: Group templates in dropdown menus. You can click the `+ New category` link right next to the field to create one instantly.
  - **Tracker**: Select a tracker (e.g. *Bug*, *Feature*) or leave as *All*.
  - **Default**: When checked, newly created issues of this Tracker will automatically be populated with these checklist items.
  - **Public**: Makes the template available across all project members.
  - **Checklist items**: Enter one item per line. Prefix any line with `#` to turn it into a bold section divider.

### 3. Quick-Add on Issue Page
On any issue page:
- Type task text into the inline quick-add input at the bottom of the checklist.
- Optionally select an **Assignee** and **Due Date**.
- Check **Section** (or type `# Section Name`) to create a bold section divider.
- Press **Add** or hit Enter to add immediately via AJAX without reloading the issue.

### 4. Issue Filters & Columns
- In the issues list (`/issues`), click **Options** and add **Checklist** to the selected columns to see live completion counters (`3/7`).
- Under **Add filter**, select **Checklist status** (*All items done*, *Has open items*, *Empty checklist*) or **Checklist item contains** to search tasks.

---

## REST API Example

```bash
# List checklist items for an issue
curl -v -H "Content-Type: application/json" -X GET \
  http://localhost:3300/issues/1/checklists.json?key=<YOUR_API_KEY>

# Add a new checklist item with assignee and due date
curl -v -H "Content-Type: application/json" -X POST \
  -d '{"subject":"Run regression tests","assigned_to_id":1,"due_date":"2026-12-01"}' \
  http://localhost:3300/issues/1/checklists.json?key=<YOUR_API_KEY>

# Toggle an item done
curl -v -H "Content-Type: application/json" -X PUT \
  http://localhost:3300/issues/1/checklists/12/done.json?key=<YOUR_API_KEY>
```

---

## Author & Maintainer

- **Arean Narrayan**
- GitHub: [@Arean82](https://github.com/Arean82)
- Email: [arean@synorastudio.in](mailto:arean@synorastudio.in)

## License

This plugin is licensed under the GNU General Public License v3 (GPL-3.0). See [GPL.txt](file:///data/redmine/plugins/redmine_issue_checklist/GPL.txt) for details.
