# frozen_string_literal: true

# html used in tabsets
module Tabs
  module DescriptionsHelper
    # Links for the tabset
    def show_description_tabs(description:)
      # type = description.parent.type_tag
      # admin = is_admin?(description)
      # assemble HTML for "tabset" for show_{type}_description
      # [
      #   description_parent_tab(description, type)
      #   edit_description_tab(description, type),
      #   destroy_description_tab(description, admin),
      #   clone_description_tab(description, type),
      #   merge_description_tab(description, type, admin),
      #   adjust_description_permissions_tab(description, type, admin),
      #   make_description_default_tab(description, type),
      #   description_project_tab(description),
      #   publish_description_draft_tab(description, type, admin)
      # ].reject(&:empty?)
    end

    def description_change_links(desc)
      type = desc.parent.type_tag
      admin = is_admin?(desc)
      [
        writer?(desc) ? edit_button(target: desc, icon: :edit) : nil,
        admin ? destroy_button(target: desc, icon: :delete) : nil,
        icon_link_to(*clone_description_tab(desc, type)),
        icon_link_to(*merge_description_tab(desc, type, admin)),
        icon_link_to(*adjust_description_permissions_tab(desc, type, admin)),
        icon_link_to(*make_description_default_tab(desc, type)),
        icon_link_to(*description_project_tab(desc)),
        icon_link_to(*publish_description_draft_tab(desc, type, admin))
      ].compact_blank.safe_join(" | ")
    end

    # Components of the above AND similar links for helpers/descriptions_helper
    def description_parent_tab(description, type)
      [:show_object.t(type: type),
       add_query_param(description.parent.show_link_args),
       { class: "#{__method__}_#{description.id}" }]
    end

    def create_description_tab(object, type)
      [:show_name_create_description.t,
       add_query_param(send(:"new_#{type}_description_path", object.id)),
       { class: "#{__method__}_#{object.id}", icon: :add }]
    end

    def edit_description_tab(description, type)
      return unless writer?(description)

      [:show_description_edit.t,
       add_query_param(send(:"edit_#{type}_description_path", description.id)),
       { class: "#{__method__}_#{description.id}", icon: :edit }]
    end

    def destroy_description_tab(description, admin)
      return unless admin

      [:show_description_destroy.t, description, { button: :destroy }]
    end

    def clone_description_tab(description, type)
      [:show_description_clone.t,
       add_query_param(
         send(:"new_#{type}_description_path",
              { clone: description.id, id: description.parent_id })
       ),
       { help: :show_description_clone_help.l,
         class: tab_id(__method__.to_s), icon: :clone }]
    end

    def merge_description_tab(description, type, admin)
      return unless admin

      [:show_description_merge.t,
       add_query_param(
         send(:"#{type}_description_merges_form_path", description.id)
       ),
       { help: :show_description_merge_help.l,
         class: tab_id(__method__.to_s), icon: :merge }]
    end

    def move_description_tab(description, type, admin)
      return unless admin

      parent_type = description.parent.type_tag.to_s
      [:show_description_move.t,
       add_query_param(
         send(:"#{type}_description_moves_form_path", description.id)
       ),
       { help: :show_description_move_help.l(parent: parent_type),
         class: tab_id(__method__.to_s), icon: :move }]
    end

    def adjust_description_permissions_tab(description, type, admin)
      return unless admin && type == :name

      [:show_description_adjust_permissions.t,
       add_query_param(
         send(:"edit_#{type}_description_permissions_path", description.id)
       ),
       { help: :show_description_adjust_permissions_help.l,
         class: tab_id(__method__.to_s), icon: :adjust }]
    end

    def make_description_default_tab(description, type)
      return unless description.public && User.current &&
                    (description.parent.description_id != description.id)

      [:show_description_make_default.t,
       add_query_param(
         send(:"make_default_#{type}_description_path", description.id)
       ),
       { button: :put, help: :show_description_make_default_help.l,
         class: tab_id(__method__.to_s), icon: :make_default }]
    end

    def description_project_tab(description)
      return unless (description.source_type == :project) &&
                    (project = description.source_object)

      [:show_object.t(type: :project), add_query_param(project.show_link_args),
       { class: tab_id(__method__.to_s) }]
    end

    def publish_description_draft_tab(description, type, admin)
      return unless admin && (type == :name) &&
                    (description.source_type != :public)

      [:show_description_publish.t,
       add_query_param(
         send(:"#{type}_description_publish_path", description.id)
       ),
       { button: :put, help: :show_description_publish_help.l,
         class: tab_id(__method__.to_s), icon: :publish }]
    end

    def new_description_for_project_tab(object, type, project)
      [project.title,
       add_query_param(
         send(:"new_#{type}_description_path",
              { project: project.id, source: "project", id: object.id })
       ),
       { class: tab_id(__method__.to_s) }]
    end

    def descriptions_index_sorts
      [
        ["name",        :sort_by_name.t],
        ["created_at",  :sort_by_created_at.t],
        ["updated_at",  :sort_by_updated_at.t],
        ["num_views",   :sort_by_num_views.t]
      ].freeze
    end
  end
end
