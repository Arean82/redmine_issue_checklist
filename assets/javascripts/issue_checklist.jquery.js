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
    this.fileInput.on('change', $.proxy(this.onFileInputChange, this));
    this.input.keypress($.proxy(this.onKeyPress, this));
    this.input.on('dragover', $.proxy(this.onDragOver, this));
    this.input.on('drop', $.proxy(this.onDrop, this));
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
  },

  onDragOver: function(event) {
    event.stopPropagation();
    event.preventDefault();
    event.originalEvent.dataTransfer.dropEffect = 'copy';
  },

  onDrop: function(event) {
    var file = event.dataTransfer.files[0];
    event.stopPropagation();
    event.preventDefault();
    if (file) {
      this.parseMultiLineFile(file);
    }
  },

  onFileInputChange: function(event) {
    var file = event.target.files[0];
    if (file) {
      this.parseMultiLineFile(file);
    }
  },

  parseMultiLineFile: function (file) {
    if (!(window.File && window.FileReader) || !file) {
      return false;
    }

    var _this = this;
    var reader = new window.FileReader();

    reader.onload = function(event) {
      var result = event.target.result;
      var lines = result.split("\n").filter(function(el) {
        return !$.isEmptyObject($.trim(el));
      });

      if (lines.length && window.confirm('Import ' + lines.length + ' checklist items?')) {
        lines.forEach(function(line) {
          var trimmed = $.trim(line);
          if (trimmed.indexOf('#') === 0) {
            _this.addChecklistItem(trimmed.substring(1).trim(), false, null, true);
          } else {
            _this.addChecklistItem(trimmed, false, null, false);
          }
        });
      }
    };

    reader.readAsText(file);
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
