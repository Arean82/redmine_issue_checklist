require 'redmine'

module RedmineIssueChecklist
  module Patches
    module IssueQueryPatch
      def self.included(base)
        base.class_eval do
          unless available_columns.any? { |c| c.name == :checklist }
            available_columns << QueryColumn.new(
              :checklist,
              caption: :label_issue_checklist_plural,
              default_order: 'desc'
            )
          end
        end
        base.prepend(InstanceMethods) unless base.ancestors.include?(InstanceMethods)
      end

      module InstanceMethods
        def initialize_available_filters
          super
          add_available_filter(
            'checklist_item',
            type: :text,
            name: l(:label_checklist_item_search)
          ) unless available_filters.key?('checklist_item')

          add_available_filter(
            'checklist_status',
            type: :list,
            values: [
              [l(:label_checklist_status_all_done), 'all_done'],
              [l(:label_checklist_status_has_undone), 'has_undone'],
              [l(:label_checklist_status_empty), 'empty']
            ],
            name: l(:label_checklist_status)
          ) unless available_filters.key?('checklist_status')
        end

        def sql_for_checklist_item_field(field, operator, value)
          db_table = IssueChecklist.table_name
          case operator
          when '~'
            sql = value.first.to_s.strip
            "EXISTS (SELECT 1 FROM #{db_table} WHERE #{db_table}.issue_id = #{Issue.table_name}.id AND LOWER(#{db_table}.subject) LIKE LOWER('%#{ActiveRecord::Base.sanitize_sql_like(sql)}%'))"
          when '!~'
            sql = value.first.to_s.strip
            "NOT EXISTS (SELECT 1 FROM #{db_table} WHERE #{db_table}.issue_id = #{Issue.table_name}.id AND LOWER(#{db_table}.subject) LIKE LOWER('%#{ActiveRecord::Base.sanitize_sql_like(sql)}%'))"
          else
            '1=1'
          end
        end

        def sql_for_checklist_status_field(field, operator, value)
          db_table = IssueChecklist.table_name
          val = value.is_a?(Array) ? value.first : value
          case val
          when 'empty'
            operator == '=' ? "NOT EXISTS (SELECT 1 FROM #{db_table} WHERE #{db_table}.issue_id = #{Issue.table_name}.id)" : "EXISTS (SELECT 1 FROM #{db_table} WHERE #{db_table}.issue_id = #{Issue.table_name}.id)"
          when 'all_done'
            cond = "EXISTS (SELECT 1 FROM #{db_table} WHERE #{db_table}.issue_id = #{Issue.table_name}.id AND #{db_table}.is_section = FALSE) AND NOT EXISTS (SELECT 1 FROM #{db_table} WHERE #{db_table}.issue_id = #{Issue.table_name}.id AND #{db_table}.is_done = FALSE AND #{db_table}.is_section = FALSE)"
            operator == '=' ? cond : "NOT (#{cond})"
          when 'has_undone'
            cond = "EXISTS (SELECT 1 FROM #{db_table} WHERE #{db_table}.issue_id = #{Issue.table_name}.id AND #{db_table}.is_done = FALSE AND #{db_table}.is_section = FALSE)"
            operator == '=' ? cond : "NOT (#{cond})"
          else
            '1=1'
          end
        end

        def value_object(object, column)
          if column.name == :checklist
            items = object.checklist.reject(&:is_section)
            if items.empty?
              ''
            else
              done_count = items.count(&:is_done)
              "#{done_count}/#{items.count}"
            end
          else
            super
          end
        end
      end
    end
  end
end

unless IssueQuery.included_modules.include?(RedmineIssueChecklist::Patches::IssueQueryPatch)
  IssueQuery.send(:include, RedmineIssueChecklist::Patches::IssueQueryPatch)
end
