# frozen_string_literal: true

# html used in tabsets
module Tabs
  module NamesHelper
    # assemble links for "tabset" for show_name
    def name_show_links(name:, user:)
      [
        [:show_name_edit_name.t, add_query_param(edit_name_path(name.id)),
         { class: "edit_name_link" }],
        [:show_name_add_name.t, add_query_param(new_name_path),
         { class: "new_name_link" }],
        edit_synonym_form_link(name),
        approve_synonym_form_link(name),
        deprecate_synonym_form_link(name),
        name_tracker_form_link(name, user)
      ].reject(&:empty?)
    end

    def basic_name_form_links(_name)
      []
    end

    def edit_synonym_form_link(name)
      return unless in_admin_mode? || !name.locked

      [:show_name_change_synonyms.t,
       add_query_param(edit_name_synonyms_path(name.id)),
       { class: "edit_name_synonym_link" }]
    end

    def approve_synonym_form_link(name)
      return unless name.deprecated && (in_admin_mode? || !name.locked)

      [:APPROVE.t, add_query_param(approve_name_synonym_form_path(name.id)),
       { class: "approve_name_synonym_link" }]
    end

    def deprecate_synonym_form_link(name)
      return unless !name.deprecated && (in_admin_mode? || !name.locked)

      [:DEPRECATE.t, add_query_param(deprecate_name_synonym_form_path(name.id)),
       { class: "deprecate_name_link" }]
    end

    def name_tracker_form_link(name, user)
      existing_name_tracker = NameTracker.find_by(name_id: name.id,
                                                  user_id: user.id)
      if existing_name_tracker
        [:show_name_email_tracking.t,
         add_query_param(edit_name_tracker_path(name.id)),
         { class: "edit_name_tracker_link" }]
      else
        [:show_name_email_tracking.t,
         add_query_param(new_name_tracker_path(name.id)),
         { class: "new_name_tracker_link" }]
      end
    end

    def name_map_show_links(name:, query:)
      [
        [:name_map_about.t(name: name.display_name),
         add_query_param(name.show_link_args),
         { class: "name_link" }],
        [*coerced_query_link(query, Location),
         { class: "name_location_query_link" }],
        [*coerced_query_link(query, Observation),
         { class: "name_observation_query_link" }]
      ]
    end

    ##########################################################################
    #
    #    Index:

    def names_index_links(query:)
      [
        new_name_link,
        names_with_observations_link(query),
        observations_of_these_names_link(query),
        descriptions_of_these_names_link(query)
      ].reject(&:empty?)
    end

    def new_name_link
      [:name_index_add_name.t, new_name_path, { class: "new_name_link" }]
    end

    def names_with_observations_link(query)
      return unless query&.flavor == :with_observations

      [:all_objects.t(type: :name), names_path(with_observations: true),
       { class: "names_with_observations_link" }]
    end

    def observations_of_these_names_link(query)
      return unless query

      [*coerced_query_link(query, Observation),
       { class: "observations_of_these_names_link" }]
    end

    def descriptions_of_these_names_link(query)
      return unless query&.coercable?(:NameDescription)

      [:show_objects.t(type: :description),
       add_query_param(name_descriptions_path),
       { class: "descriptions_of_these_names_link" }]
    end

    ### Forms
    def name_form_new_links
      [
        [:all_objects.t(type: :name), names_path, { class: "names_link" }]
      ]
    end

    def name_form_edit_links(name:)
      [
        [:cancel_and_show.t(type: :name), add_query_param(name_path(name.id)),
         { class: "name_link" }],
        [:all_objects.t(type: :name), names_path, { class: "names_link" }]
      ]
    end

    def name_versions_links(name:)
      [
        [:show_name.t(name: name.display_name), name_path(name.id),
         { class: "name_link" }]
      ]
    end

    def name_return_link(name:)
      [
        [:cancel_and_show.t(type: :name), add_query_param(name_path(name.id)),
         { class: "name_link" }]
      ]
    end
  end
end
