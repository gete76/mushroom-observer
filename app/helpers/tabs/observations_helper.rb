# frozen_string_literal: true

# html used in tabsets
module Tabs
  module ObservationsHelper
    # assemble links for "tabset" for show_observation
    # actually a list of links and the interest icons
    def show_observation_tabs(obs:, user:)
      [
        observation_manage_lists_tab(obs, user),
        *obs_change_tabs(obs)&.reject(&:empty?)
      ]
    end

    ########################################################################
    # LINKS FOR PANELS
    #
    # Used in the observation panel

    def send_observer_question_tab(obs)
      [:show_observation_send_question.l,
       add_query_param(new_question_for_observation_path(obs.id)),
       { class: tab_id(__method__.to_s), icon: :email }]
    end

    # Used in the lists panel
    # N+1: this looks up User.current.species_lists. Mercifully quick.
    def observation_manage_lists_tab(obs, user)
      return unless user&.species_list_ids&.any?

      [:show_observation_manage_species_lists.l,
       add_query_param(edit_observation_species_lists_path(obs.id)),
       { class: tab_id(__method__.to_s), icon: :manage_lists }]
    end

    # Name panel -- generates HTML

    # uses create_links_to with extra_args { class: "d-block" }
    # the hiccup here is that list_descriptions is already HTML, an inline list
    def name_links_on_mo(name:)
      tabs = create_links_to(obs_related_name_tabs(name), { class: "d-block" })
      tabs += obs_name_description_tabs(name)
      tabs += create_links_to([occurrence_map_for_name_tab(name)],
                              { class: "d-block" })
      tabs.reject(&:empty?)
    end

    def obs_related_name_tabs(name)
      [
        show_object_tab(name,
                        :show_name.t(name: name.display_name_brief_authors)),
        observations_of_name_tab(name),
        observations_of_look_alikes_tab(name),
        observations_of_related_taxa_tab(name)
      ]
    end

    def observations_of_name_tab(name)
      [:show_observation_more_like_this.l,
       observations_path(name: name.id),
       { class: tab_id(__method__.to_s) }]
    end

    def observations_of_look_alikes_tab(name)
      [:show_observation_look_alikes.l,
       observations_path(name: name.id, look_alikes: "1"),
       { class: tab_id(__method__.to_s) }]
    end

    def observations_of_related_taxa_tab(name)
      [:show_observation_related_taxa.l,
       observations_path(name: name.id, related_taxa: "1"),
       { class: tab_id(__method__.to_s) }]
    end

    # from descriptions_helper
    def obs_name_description_tabs(name)
      list_descriptions(object: name, type: :name)&.map do |link|
        tag.div(link)
      end
    end

    def observation_map_tab(mappable)
      return unless mappable

      [:MAP.t, add_query_param(map_observation_path),
       { class: tab_id(__method__.to_s) }]
    end

    def name_links_web(name:)
      tabs = create_links_to(observation_web_name_tabs(name),
                             { class: "d-block" })
      tabs.reject(&:empty?)
    end

    def observation_web_name_tabs(name)
      [
        mycoportal_name_tab(name),
        mycobank_name_search_tab(name),
        google_images_for_name_tab(name)
      ]
    end

    def observation_hide_thumbnail_map_tab(obs)
      [:show_observation_hide_map.l,
       javascript_hide_thumbnail_map_path(id: obs.id),
       { class: tab_id(__method__.to_s), icon: :hide }]
    end

    def new_image_for_observation_tab(obs)
      [:show_observation_add_images.l,
       new_image_for_observation_path(obs.id),
       { class: tab_id(__method__.to_s), icon: :add }]
    end

    def reuse_images_for_observation_tab(obs)
      [:show_observation_reuse_image.l,
       reuse_images_for_observation_path(obs.id),
       { class: tab_id(__method__.to_s), icon: :reuse }]
    end

    def remove_images_from_observation_tab(obs)
      [:show_observation_remove_images.l,
       remove_images_from_observation_path(obs.id),
       { class: tab_id(__method__.to_s), icon: :remove }]
    end

    ############################################
    # INDEX

    def observations_index_tabs(query:)
      links = [
        *observations_at_where_tabs(query), # maybe multiple links
        map_observations_tab(query),
        *observations_coerced_query_tabs(query), # multiple links
        observations_add_to_list_tab(query),
        observations_download_as_csv_tab(query)
      ]
      links.reject(&:empty?)
    end

    # for debugging
    def dummy_disable_tab
      ["Dummy link",
       "https://google.com",
       { class: tab_id(__method__.to_s), data: { action: "links#disable" } }]
    end

    def observations_at_where_tabs(query)
      # Add some extra links to the index user is sent to if they click on an
      # undefined location.
      return [] unless query.flavor == :at_where

      [
        define_location_tab(query),
        assign_undefined_location_tab(query),
        locations_index_tab
      ]
    end

    # these are from the observations form
    def define_location_tab(query)
      [:list_observations_location_define.l,
       add_query_param(new_location_path(where: query.params[:user_where])),
       { class: tab_id(__method__.to_s) }]
    end

    def assign_undefined_location_tab(query)
      [:list_observations_location_merge.l,
       add_query_param(matching_locations_for_observations_path(
                         where: query.params[:user_where]
                       )),
       { class: tab_id(__method__.to_s) }]
    end

    def observations_index_sorts
      [
        ["rss_log", :sort_by_activity.l],
        ["date", :sort_by_date.l],
        ["created_at", :sort_by_posted.l],
        # kind of redundant to sort by rss_logs, though not strictly ===
        # ["updated_at", :sort_by_updated_at.l],
        ["name", :sort_by_name.l],
        ["user", :sort_by_user.l],
        ["confidence", :sort_by_confidence.l],
        ["thumbnail_quality", :sort_by_thumbnail_quality.l],
        ["num_views", :sort_by_num_views.l]
      ].freeze
    end

    def map_observations_tab(query)
      [:show_object.t(type: :map),
       map_observations_path(q: get_query_param(query)),
       { class: tab_id(__method__.to_s), data: { action: "links#disable" } }]
    end

    # NOTE: coerced_query_tab returns an array
    def observations_coerced_query_tabs(query)
      [
        coerced_location_query_tab(query),
        coerced_name_query_tab(query),
        coerced_image_query_tab(query)
      ]
    end

    def observations_add_to_list_tab(query)
      [:list_observations_add_to_list.l,
       add_query_param(edit_species_list_observations_path, query),
       { class: tab_id(__method__.to_s) }]
    end

    def observations_download_as_csv_tab(query)
      [:list_observations_download_as_csv.l,
       add_query_param(new_observations_download_path, query),
       { class: tab_id(__method__.to_s) }]
    end

    ############################################
    # FORMS

    def observation_form_new_tabs
      [new_herbarium_tab]
    end

    def observation_form_edit_tabs(obs:)
      [object_return_tab(obs)]
    end

    def observation_maps_tabs(query:)
      [
        coerced_observation_query_tab(query),
        coerced_location_query_tab(query)
      ]
    end

    def naming_form_new_title(obs:)
      :create_naming_title.t(id: obs.id)
    end

    def naming_form_new_tabs(obs:)
      [object_return_tab(obs)]
    end

    def naming_form_edit_title(obs:)
      :edit_naming_title.t(id: obs.id)
    end

    def naming_form_edit_tabs(obs:)
      [object_return_tab(obs)]
    end

    def naming_suggestion_tabs(obs:)
      [object_return_tab(obs)]
    end

    def observation_list_tabs(obs:)
      [object_return_tab(obs)]
    end

    def observation_images_edit_tabs(image:)
      [object_return_tab(image)]
    end

    def observation_images_new_tabs(obs:)
      [
        object_return_tab(obs),
        edit_observation_tab(obs)
      ]
    end

    # Note this takes `obj:` not `obs:`
    def observation_images_remove_tabs(obj:)
      [
        object_return_tab(obj),
        edit_observation_tab(obj)
      ]
    end

    def observation_images_reuse_tabs(obs:)
      [
        object_return_tab(obs),
        edit_observation_tab(obs)
      ]
    end

    def observation_download_tabs
      [observations_index_tab]
    end

    def observations_index_tab
      [:download_observations_back.l,
       add_query_param(observations_path),
       { class: tab_id(__method__.to_s) }]
    end

    def obs_change_tabs(obs)
      return unless check_permission(obs)

      [
        edit_observation_tab(obs),
        destroy_observation_tab(obs)
      ]
    end

    # Buttons in "Details" panel header
    def obs_change_links(obs)
      return unless check_permission(obs)

      [
        edit_button(target: obs, icon: :edit),
        destroy_button(target: obs, icon: :delete)
      ].safe_join(" | ")
    end

    def edit_observation_tab(obs)
      [:edit_object.t(type: Observation),
       add_query_param(edit_observation_path(obs.id)),
       { class: "#{tab_id(__method__.to_s)}_#{obs.id}", icon: :edit }]
    end

    def destroy_observation_tab(obs)
      [nil, obs, { button: :destroy }]
    end
  end
end
