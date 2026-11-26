var parsedImportItems = [];

function openChecklistImportModal() {
  $('#checklist_import_modal').fadeIn(200);
}

function closeChecklistImportModal() {
  $('#checklist_import_modal').fadeOut(200);
  $('#checklist_import_file_input').val('');
  $('#template_file_import_input').val('');
  $('#checklist_import_filename').text('');
  $('#checklist_import_preview_area').hide();
  $('#confirm_checklist_import_btn').hide();
  parsedImportItems = [];
}

function openLogTimeModal(itemId, subject) {
  var issueId = $('#checklist_log_time_form').closest('#issue_checklist').length > 0 ?
                $('#issue_checklist').closest('body').find('h2:contains("#")').text() : '';
  
  $('#log_time_item_title').text(subject);
  $('#log_time_hours').val('');
  $('#log_time_comments').val('Checklist: ' + subject);
  
  var formAction = window.location.pathname.replace(/\/$/, '') + '/checklists/' + itemId + '/log_time';
  $('#checklist_log_time_form').attr('action', formAction);
  $('#checklist_log_time_modal').fadeIn(200);
}

function closeLogTimeModal() {
  $('#checklist_log_time_modal').fadeOut(200);
}

// Smart parser for TXT and Markdown files without using regex
function parseChecklistText(rawText) {
  var lines = rawText.split("\n");
  var items = [];

  for (var i = 0; i < lines.length; i++) {
    var rawLine = lines[i];
    var line = $.trim(rawLine);
    if (!line || line.length === 0) continue;

    var isSection = false;
    var isDone = false;
    var subject = line;

    // 1. Markdown Header detection (#, ##, ###)
    if (line.indexOf('#') === 0) {
      isSection = true;
      var clean = line;
      while (clean.indexOf('#') === 0) {
        clean = clean.substring(1);
      }
      subject = $.trim(clean);
    }
    // 2. Markdown Checkbox detection: "- [ ]", "* [ ]", "- [x]", "* [x]"
    else if (line.indexOf('- [x]') === 0 || line.indexOf('- [X]') === 0 || line.indexOf('* [x]') === 0 || line.indexOf('* [X]') === 0) {
      isDone = true;
      subject = $.trim(line.substring(5));
    }
    else if (line.indexOf('- [ ]') === 0 || line.indexOf('* [ ]') === 0) {
      isDone = false;
      subject = $.trim(line.substring(5));
    }
    // 3. Bullet list prefixes: "-", "*", "+"
    else if (line.indexOf('- ') === 0 || line.indexOf('* ') === 0 || line.indexOf('+ ') === 0) {
      subject = $.trim(line.substring(2));
    }

    if (subject.length > 0) {
      items.push({
        subject: subject,
        is_section: isSection,
        is_done: isDone,
        selected: true
      });
    }
  }

  return items;
}

function renderImportPreview(items) {
  parsedImportItems = items;
  var $tbody = $('#checklist_preview_table_body');
  $tbody.empty();

  var taskCount = 0;
  var sectionCount = 0;

  for (var i = 0; i < items.length; i++) {
    var it = items[i];
    if (it.is_section) sectionCount++; else taskCount++;

    var $tr = $('<tr>');
    var $cb = $('<input type="checkbox" class="preview-item-checkbox" checked data-index="' + i + '">');
    var $tdCheck = $('<td>').append($cb);

    var typeBadge = it.is_section ?
      '<span class="badge" style="background:#586069; color:#fff;">Section</span>' :
      (it.is_done ? '<span class="badge badge-success">Done</span>' : '<span class="badge badge-info">Task</span>');

    var $tdType = $('<td>').html(typeBadge);
    var $input = $('<input type="text" class="preview-item-edit-field" data-index="' + i + '">').val(it.subject);
    if (it.is_section) {
      $input.css('font-weight', 'bold');
    }
    var $tdSubject = $('<td>').append($input);

    $tr.append($tdCheck).append($tdType).append($tdSubject);
    $tbody.append($tr);
  }

  $('#checklist_preview_counts').text(taskCount + ' tasks, ' + sectionCount + ' sections');
  $('#checklist_import_preview_area').show();
  $('#confirm_checklist_import_btn').show();
  $('#confirm_template_import_btn').show();
}

function handleFileSelected(file) {
  if (!file) return;
  $('#checklist_import_filename').text(file.name);
  var reader = new FileReader();
  reader.onload = function(e) {
    var content = e.target.result;
    var parsed = parseChecklistText(content);
    if (parsed.length === 0) {
      alert('No valid checklist items found in file.');
      return;
    }
    renderImportPreview(parsed);
  };
  reader.readAsText(file);
}

function applyChecklistImportToIssue(issueId) {
  var finalItems = [];
  $('#checklist_preview_table_body tr').each(function() {
    var $cb = $(this).find('.preview-item-checkbox');
    if ($cb.is(':checked')) {
      var idx = parseInt($cb.data('index'), 10);
      var subj = $(this).find('.preview-item-edit-field').val();
      finalItems.push({
        subject: subj,
        is_section: parsedImportItems[idx].is_section ? '1' : '0',
        is_done: parsedImportItems[idx].is_done ? '1' : '0'
      });
    }
  });

  if (finalItems.length === 0) {
    alert('Please select at least one item to import.');
    return;
  }

  var mode = $('input[name="import_action_mode"]:checked').val() || 'append';

  $.ajax({
    url: '/issues/' + issueId + '/checklists/batch_import',
    type: 'POST',
    data: {
      items: finalItems,
      mode: mode
    },
    dataType: 'json',
    success: function(resp) {
      closeChecklistImportModal();
      location.reload();
    },
    error: function(xhr) {
      alert('Failed to import checklist items.');
    }
  });
}

function applyChecklistImportToTemplate() {
  var mode = $('input[name="template_import_mode"]:checked').val() || 'append';
  var lines = [];

  $('#checklist_preview_table_body tr').each(function() {
    var $cb = $(this).find('.preview-item-checkbox');
    if ($cb.is(':checked')) {
      var idx = parseInt($cb.data('index'), 10);
      var subj = $(this).find('.preview-item-edit-field').val();
      if (parsedImportItems[idx].is_section) {
        lines.push('# ' + subj);
      } else {
        lines.push(subj);
      }
    }
  });

  var $ta = $('#template_items_textarea');
  var currentVal = $.trim($ta.val());

  if (mode === 'replace' || currentVal.length === 0) {
    $ta.val(lines.join("\n"));
  } else {
    $ta.val(currentVal + "\n" + lines.join("\n"));
  }

  closeChecklistImportModal();
}

$(document).ready(function() {
  $('#checklist_form_items').sortable();

  var hideCompleted = localStorage.getItem('hide_completed_checklists') === '1';

  function applyHideCompletedState() {
    var $completedItems = $('#issue_checklist_items li.is-done-checklist-item');
    if (hideCompleted) {
      $completedItems.hide();
      $('#toggle_completed_checklists_btn').text('Show completed (' + $completedItems.length + ')');
    } else {
      $completedItems.show();
      $('#toggle_completed_checklists_btn').text('Hide completed');
    }
  }

  applyHideCompletedState();

  $('#toggle_completed_checklists_btn').click(function(e) {
    e.preventDefault();
    hideCompleted = !hideCompleted;
    localStorage.setItem('hide_completed_checklists', hideCompleted ? '1' : '0');
    applyHideCompletedState();
  });

  $('#open_checklist_import_modal_btn').click(function(e) {
    e.preventDefault();
    openChecklistImportModal();
  });

  $('#checklist_import_file_input').on('change', function(e) {
    var file = e.target.files[0];
    handleFileSelected(file);
  });

  $('#template_file_import_input').on('change', function(e) {
    var file = e.target.files[0];
    if (file) {
      openChecklistImportModal();
      handleFileSelected(file);
    }
  });

  $('#checklist_preview_check_all').click(function() {
    var isChecked = $(this).is(':checked');
    $('.preview-item-checkbox').prop('checked', isChecked);
  });
});

function updateChecklistProgress() {
  var $items = $('#issue_checklist_items li:not(.checklist-section-item)');
  var total = $items.length;
  var done = $items.filter('.is-done-checklist-item').length;
  var pct = total > 0 ? Math.round((done / total) * 100) : 0;

  $('.checklist-count-badge').text(done + '/' + total + ' (' + pct + '%)');
  if (pct === 100) {
    $('.checklist-count-badge').removeClass('badge-info').addClass('badge-success');
  } else {
    $('.checklist-count-badge').removeClass('badge-success').addClass('badge-info');
  }
  $('.checklist-progress-fill').css('width', pct + '%');

  if (localStorage.getItem('hide_completed_checklists') === '1') {
    $('#issue_checklist_items li.is-done-checklist-item').hide();
  }
}

var Redmine = Redmine || {};

$.fn.issue_check_list = function(element, input, button, fileInput) {};

Redmine.IssueChecklist = jQuery.klass({
  init: function(element, input, button, fileInput) {
    this.element   = $('#' + element);
    this.input     = $('#' + input);
    this.button    = $('#' + button);
    this.fileInput = $('#' + fileInput);
    this.sectionButton = $('#add_checklist_section_button');
    this.templateSelector = $('#checklist_template_selector');
    this.templateBtn = $('#apply_checklist_template_btn');

    this.checklist = {};
    this.button.click($.proxy(this.readChecklist, this));
    if (this.sectionButton.length > 0) {
      this.sectionButton.click($.proxy(this.readSection, this));
    }
    if (this.templateBtn.length > 0) {
      this.templateBtn.click($.proxy(this.applyTemplate, this));
    }
    this.input.keypress($.proxy(this.onKeyPress, this));

    // Dynamic Tracker Checklist Autoload on new issue form
    var self = this;
    $(document).off('change.checklist_tracker', '#issue_tracker_id').on('change.checklist_tracker', '#issue_tracker_id', function() {
      var trackerId = $(this).val();
      if (!trackerId) return;

      var currentItems = $('#checklist_form_items .checklist-item');
      // Only auto-populate if user has not yet customized the checklist
      if (currentItems.length === 0) {
        var opt = self.templateSelector.find('option[data-tracker-id="' + trackerId + '"][data-is-default="true"]').first();
        if (opt.length > 0) {
          var rawItems = opt.data('items');
          var items = typeof rawItems === 'string' ? JSON.parse(rawItems) : rawItems;
          if (items && items.length > 0) {
            for (var i = 0; i < items.length; i++) {
              var it = items[i];
              self.addChecklistItem(it.subject, it.is_done, null, it.is_section);
            }
          }
        }
      }
    });
  },

  readChecklist: function(event) {
    this.addChecklistItem(this.input.val(), false, null, false);
    this.input.val('');
    if (event) event.preventDefault();
  },

  readSection: function(event) {
    var val = this.input.val();
    if (val && $.trim(val).length > 0) {
      this.addChecklistItem(val, false, null, true);
      this.input.val('');
    }
    if (event) event.preventDefault();
  },

  applyTemplate: function(event) {
    if (event) event.preventDefault();
    var sel = this.templateSelector.find('option:selected');
    var rawItems = sel.data('items');
    if (!rawItems) return;

    var items = typeof rawItems === 'string' ? JSON.parse(rawItems) : rawItems;
    if (items && items.length > 0) {
      for (var i = 0; i < items.length; i++) {
        var it = items[i];
        this.addChecklistItem(it.subject, it.is_done, null, it.is_section);
      }
    }
  },

  onKeyPress: function(event) {
    if (13 == event.keyCode) {
      this.readChecklist(event);
      event.preventDefault();
    }
  },

  addChecklistItem: function(checklistItem, isDone, id, isSection) {
    if ($.isEmptyObject(checklistItem)) {
      return;
    }

    isDone = isDone || false;
    isSection = isSection || false;

    var label = $(document.createElement('span'));
    var hiddenSubject = $(document.createElement('input'));
    hiddenSubject.attr({'type': 'hidden', 'name': 'check_list_items[][subject]', 'value': $.trim(checklistItem)});
    
    var hiddenSection = $(document.createElement('input'));
    hiddenSection.attr({'type': 'hidden', 'name': 'check_list_items[][is_section]', 'value': isSection ? '1' : '0'});

    var delBtn = $(document.createElement('span'));
    delBtn.attr({'href': '#', 'class': 'delete icon icon-del'});

    if (isSection) {
      label.attr({ 'class': 'checklist-item checklist-item-section' })
           .append(hiddenSubject)
           .append(hiddenSection)
           .append($('<strong>').text($.trim(checklistItem)))
           .append(delBtn);
    } else {
      var checkbox = $(document.createElement('input'));
      checkbox.attr({'type': 'checkbox', 'name': 'check_list_items[][is_done]', 'value': '1', 'id': 'checklist_item_checkbox_' + (id || Math.random())});
      if (isDone == true) {
        checkbox.attr('checked', 'checked');
        label.addClass('is-done-checklist-item');
      }
      label.attr({ 'class': 'checklist-item' })
           .append(hiddenSubject)
           .append(hiddenSection)
           .append(checkbox)
           .append(document.createTextNode(' ' + $.trim(checklistItem) + ' '))
           .append(delBtn);

      checkbox.click(function() {
        if ($(this).is(':checked')) {
          label.addClass('is-done-checklist-item');
        } else {
          label.removeClass('is-done-checklist-item');
        }
      });
    }

    this.checklist[checklistItem] = 1;
    this.element.append(label);

    delBtn.click($.proxy(function() {
      this.checklist[checklistItem] = null;
      label.remove();
    }, this));
  },

  addChecklist: function(checklist) {
    for (var i = 0; i < checklist.length; i++) {
      this.addChecklistItem(checklist[i]['subject'], checklist[i]['is_done'], checklist[i]['id'], checklist[i]['is_section']);
    }
  },

  getChecklist: function() {
    return this.checklist;
  }
});

function observeIssueChecklistField(element, input, add_button, fileInput) {
  issueChecklist = new Redmine.IssueChecklist(element, input, add_button, fileInput);
}

function createIssueChecklist(checkList) {
  issueChecklist.addChecklist(checkList);
}

function checklist_item_done(elem, url, id) {
  var $li = $('#checklist_item_' + id);
  var $cb = $(elem);
  var isChecked = $cb.is(':checked');

  if (isChecked) {
    $li.addClass('is-done-checklist-item');
  } else {
    $li.removeClass('is-done-checklist-item');
  }
  updateChecklistProgress();

  $.ajax({
    url: url,
    type: 'POST',
    dataType: 'script'
  });
}
