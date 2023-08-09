# frozen_string_literal: true

# Custom Tabset Helpers for Herbaria views
# NOTE: this uses ids not classes for identifiers, change this
module Tabs
  module HerbariaHelper
    # link attribute arrays
    def herbaria_index_links(query:)
      links ||= []
      unless query&.flavor == :all
        links << [:herbarium_index_list_all_herbaria.l,
                  herbaria_path(flavor: :all), { id: "all_herbaria_link" }]
      end
      unless query&.flavor == :nonpersonal
        links << [:herbarium_index_nonpersonal_herbaria.l,
                  herbaria_path(flavor: :nonpersonal),
                  { id: "all_nonpersonal_herbaria_link" }]
      end
      links << [:create_herbarium.l, new_herbarium_path,
                { id: "new_herbarium_link" }]
    end

    # Composed links because there's a destroy_button
    def herbarium_show_tabs(herbarium:, user:)
      tabs = []
      if herbarium.curators.empty? ||
         herbarium.curator?(user) || in_admin_mode?
        tabs += [
          link_to(:edit_herbarium.t,
                  add_query_param(edit_herbarium_path(herbarium.id))),
          destroy_button(
            name: :destroy_object.t(type: :herbarium),
            target: herbarium_path(herbarium,
                                   back: url_after_delete(herbarium)),
            id: "delete_herbarium_link"
          )
        ]
      end
      tabs += [
        link_to(:create_herbarium.t,
                add_query_param(new_herbarium_path),
                id: "new_herbarium_link"),
        link_to(:herbarium_index.t,
                add_query_param(herbaria_path(flavor: :nonpersonal)),
                id: "herbarium_index_link")
      ]
      tabs
    end

    # link attribute arrays
    def herbarium_form_new_links
      [[:herbarium_index.t,
        add_query_param(herbaria_path(flavor: :nonpersonal)),
        { id: "herbarium_index_link" }]]
    end

    # link attribute arrays
    def herbarium_form_edit_links(herbarium:)
      [
        [:cancel_and_show.t(type: :herbarium),
         add_query_param(herbarium_path(herbarium)),
         { id: "herbarium_link" }],
        [:herbarium_index.t,
         add_query_param(herbaria_path(flavor: :nonpersonal)),
         { id: "herbarium_index_link" }]
      ]
    end
  end
end
