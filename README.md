# Redmine Issue Checklist Plugin (PRO Edition)

[![Redmine 5.x / 6.x / 7.0+](https://img.shields.io/badge/Redmine-5.x%20%7C%206.x%20%7C%207.0%2B-blue.svg)](http://www.redmine.org)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

Enterprise issue checklist and task breakdown platform for Redmine, providing template workflows, automatic tracker task population, structured checklist custom fields, issue query filters with visual progress bars, strict issue closure validation (DoD), checklist-to-sub-issue conversion, standalone daily/team checklists on My Page, journal audit history, email notifications, sub-task assignees, due dates, per-item spent time logging, inline quick-add, bulk actions, mobile touch sorting, PDF exports, interactive Markdown/TXT file import with live preview, and complete Redmine-standard REST API support (JSON & XML).

Developed and maintained by **Arean Narrayan** ([@Arean82](https://github.com/Arean82)).

---

## Features (PRO Edition)

- **Block Issue Closure If Checklist Incomplete (DoD Enforcer)**:
  - Configurable setting under **Administration > Plugins > Configure**.
  - Prevents resolving or closing an issue if open checklist tasks remain, highlighting the exact unfinished tasks.
- **Convert Checklist Item to Sub-Issue**:
  - 1-click promotion icon next to any checklist item converts it into a formal child issue.
  - Automatically inherits parent issue properties: Project, Tracker, Category, Target Version, Assignee, Priority, and Due Date.
  - Replaces the checklist item with a clickable `#ID` link in the checklist and logs a note in the issue journal.
  - If project validation rules require additional custom fields, automatically redirects to the new issue form pre-filled.
  - Quick-add bar also offers a direct `[Sub-Issue]` option.
- **Standalone Daily & Team Checklists on My Page**:
  - Addable to `/my/page` via the *Add block...* dropdown.
  - Two integrated views: **Daily Routine / Team Tasks** (standalone recurring items with auto-daily uncheck) and **Pending Issue Tasks**.
  - Filter pills to view **My Tasks** vs. **Team Tasks**.
  - Automated midnight reset option via background cron/rake task.
- **Bulk Actions**: 1-click **Check all** and **Uncheck all** toolbar buttons.
- **Mobile Touch Sorting**: Touch drag-and-drop ordering powered by touch-punch polyfill.
- **PDF Export Formatting**: Injects structured checklists (`[X]` / `[ ]`) directly into Redmine's native issue PDF exports.
- **Interactive Issue Checklists**: Add, sort, toggle, and delete checklist items directly on issues with real-time UI updates.
- **Direct Inline Quick-Add**: Add checklist items and section headers directly from the issue view with assignees and due dates without opening full edit forms.
- **Per-Item Spent Time Logging**: Clock icon next to each checklist item to log spent time and activity with comments automatically referencing the task.
- **Visual Progress Bar in Issue Queries**: Displays a dynamic mini-progress bar (`completed/total` with gradient coloring) directly in the **Checklist** column on `/issues`.
- **Import from TXT / Markdown (`.md`) with Live Preview**:
  - Upload `.txt` or `.md` files.
  - Smart-detects task lines (`Item`), Markdown checkboxes (`- [ ]`, `- [x]`), and headers (`#`, `##`) into section headers.
  - Interactive preview table to toggle, review, or edit items before committing.
  - Choose between **Append** to existing list or **Replace**.
- **Assignees & Due Dates per Item**: Assign team members and deadlines to individual checklist tasks with overdue indicators.
- **Visual Progress Bar & Filter**: Real-time progress bar reflecting completion percentage and a quick "Hide Completed" toggle button.
- **Checklist Sections & Groups**: Group checklist items into distinct logical sections by prefixing headers with `#`.
- **Checklist Templates & Categories**: Create reusable checklist templates organized by category for project-wide or global use, with category filtering and breadcrumb navigation.
- **Automatic Checklists by Tracker**: Designate default checklist templates for specific trackers (e.g. *Bug*, *Feature*, *QA Task*) so newly created issues automatically inherit the checklist.
- **Checklist Cloning & Export**: Quick-clone checklist items from any other issue, or export checklists directly to Markdown (`.md`).
- **Standard Redmine REST API**: Complete CRUD + Done action support in both JSON and XML conforming to standard Redmine API conventions.
- **Issue Query Columns & Filters**:
  - Adds a **Checklist** column in the issues list (`/issues`) displaying task progress (`completed/total`).
  - Search filter: **Checklist item contains** text search.
  - Status filter: **Checklist status** (*All items done*, *Has open items*, *Empty checklist*).
- **Change History & Audit Trail**: Full journal logging when checklist items are toggled, added, or modified.
- **Email Notifications**: Automatically dispatches notification emails to assignees and watchers on checklist changes.
- **Automatic Done Ratio**: Optionally recalculate the issue `% Done` automatically based on completed items.

---

## REST API Reference

All endpoints support authentication via Redmine API Access Key (`key=...` parameter or `X-Redmine-API-Key: ...` header) or HTTP Basic Authentication. Both `.json` and `.xml` formats are supported.

### 1. List Issue Checklists
- **URL**: `GET /issues/:issue_id/checklists.json`
- **Response**:
```json
{
  "checklists": [
    {
      "id": 12,
      "issue_id": 45,
      "subject": "Verify API responses",
      "is_done": false,
      "is_section": false,
      "position": 1,
      "assigned_to": { "id": 1, "name": "Admin" },
      "due_date": "2026-12-01",
      "converted_issue_id": null,
      "created_at": "2026-11-26T10:00:00Z",
      "updated_at": "2026-11-26T10:00:00Z"
    }
  ]
}
```

### 2. Show Checklist Item
- **URL**: `GET /issues/:issue_id/checklists/:id.json`
- **Response**:
```json
{
  "checklist": {
    "id": 12,
    "issue_id": 45,
    "subject": "Verify API responses",
    "is_done": false,
    "is_section": false,
    "position": 1,
    "assigned_to": { "id": 1, "name": "Admin" },
    "due_date": "2026-12-01"
  }
}
```

### 3. Create Checklist Item
- **URL**: `POST /issues/:issue_id/checklists.json`
- **Payload**:
```json
{
  "checklist": {
    "subject": "Deploy to staging",
    "is_section": false,
    "assigned_to_id": 1,
    "due_date": "2026-12-05"
  }
}
```
- **Response**: Status `201 Created` with `Location` header and created checklist object.

### 4. Update Checklist Item
- **URL**: `PUT /issues/:issue_id/checklists/:id.json`
- **Payload**:
```json
{
  "checklist": {
    "subject": "Deploy to production",
    "is_done": true,
    "due_date": "2026-12-06"
  }
}
```
- **Response**: Status `204 No Content` / `200 OK`.

### 5. Toggle Checklist Done
- **URL**: `PUT /issues/:issue_id/checklists/:id/done.json`
- **Response**: Status `200 OK` with updated checklist state.

### 6. Delete Checklist Item
- **URL**: `DELETE /issues/:issue_id/checklists/:id.json`
- **Response**: Status `204 No Content` / `200 OK`.

---

## Configuration & Usage Manual

### 1. Permissions
Navigate to **Administration > Roles and permissions** and configure:
- `View checklist items`: Allows seeing checklists on issues.
- `Check/uncheck checklist items`: Allows marking checklist tasks done or open.
- `Edit checklist items`: Allows creating, deleting, quick-adding, importing, and managing templates.
- `Log time`: Allows logging spent time against individual checklist items.
- `Add issues`: Enables 1-click conversion from checklist item to child issue.

### 2. Plugin Configuration Screen
Navigate to **Administration > Plugins > Redmine Issue Checklist Plugin > Configure** (`/settings/plugin/redmine_issue_checklist`):

1. **General & Change Rules**:
   - `Block issue closure if checklist items are incomplete`: Enforces DoD by preventing issue closing when checklist items are pending.
   - `Save changes to the issue log`: Logs checklist edits and completions in issue journal histories.
   - `Automatically change the issue done ratio`: Auto-calculates issue `% Done` based on completed checklist items.
2. **Issue View & Toolbar**:
   - `Enable bulk mark done / open actions`: Shows "Check all" and "Uncheck all" toolbar buttons.
   - `Format checklist items in issue PDF exports`: Formats checklist items in native Redmine PDF issue exports.
3. **Templates & Categories**:
   - `Display Checklist Templates in Administration menu`: Displays the checklist templates link under Administration.
   - `Enable category filter on templates list`: Adds a fast category filter dropdown.
   - `Fallback to new issue page on convert error`: Automatically redirects to new issue form if required project custom fields fail during conversion.
4. **My Page & Daily Routines**:
   - `Enable My Checklists widget on My Page`: Allows adding the personal checklist block to `/my/page`.
   - `Enable My / Team task filters`: Adds tabs to segment personal and team tasks.
   - `Daily recurring items reset mode`: Choose between automatic page-access reset or background cron.
   - **Cron Command**:
     ```bash
     0 0 * * * cd /data/redmine && bundle exec rake redmine:issue_checklist:reset_daily_routines RAILS_ENV=production
     ```

---

## Author & Maintainer

- **Arean Narrayan**
- GitHub: [@Arean82](https://github.com/Arean82)
- Email: [arean@synorastudio.in](mailto:arean@synorastudio.in)

## License

This plugin is licensed under the GNU General Public License v3 (GPL-3.0). See [LICENSE](file:///data/redmine/plugins/redmine_issue_checklist/LICENSE) for details.
