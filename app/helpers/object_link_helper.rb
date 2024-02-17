# frozen_string_literal: true

# helpers for creating links in views
module ObjectLinkHelper
  # Wrap location name in link to show_location OR observations/index.
  #
  # NEW 2024-02-01 AN: Only accepts a postal format string for `where`, e.g.
  #   Location.name, Observation.where, SpeciesList.where, User.location.name
  #
  # This method prints both postal and scientific formats, shown/hidden with
  # CSS, using a governing class on the <body> that has the user's preference
  #
  #   Where: <%= location_link(obs.where, obs.location) %>
  #
  def location_link(where, location, count = nil, click = false)
    if location
      location = Location.find(location) unless location.is_a?(AbstractModel)
      link_string = where_string(location.name, count)
      link_string += " [#{:click_for_map.t}]" if click
      link_to(link_string, location_path(id: location.id),
              { id: "show_location_link_#{location.id}" })
    else
      link_string = where_string(where, count)
      link_string += " [#{:SEARCH.t}]" if click
      link_to(link_string, observations_path(where: where),
              { id: "index_observations_at_where_link" })
    end
  end

  # Wrap both formats of location.name in spans,
  #   maybe adding a count, and wrap the whole thing in a span too:
  #   <span><span class="location-postal">where</span> \
  #         <span class="location-scientific">where</span> (count)</span>
  #
  #   Where: <%= where_string(obs.where) %>
  #
  def where_string(where, count = nil)
    postal = tag.span(where, class: "location-postal")
    scientific = tag.span(Location.reverse_name(where),
                          class: "location-scientific")

    add_count = count ? " (#{count})" : ""
    tag.span { [postal, scientific, add_count].safe_join }
  end

  # Wrap name in link to show_name. Takes id or object
  #
  #   Parent: <%= name_link(name.parent) %>
  #
  def name_link(name, str = nil)
    if name.is_a?(Integer)
      str ||= "#{:NAME.t} ##{name}"
      link_to(str, name_path(name), { id: "show_name_link_#{name}" })
    else
      str ||= name.display_name_brief_authors.t
      link_to(str, name_path(name.id),
              { id: "show_name_link_#{name.id}" })
    end
  end

  # ----- links to names and records at external websites ----------------------

  def ascomycete_org_name_search_url(name)
    "https://ascomycete.org/Search-Results?search=" \
    "#{name.text_name.tr(" ", "+")}"
  end

  def gbif_name_search_url(name)
    "https://www.gbif.org/species/search?q=#{name.text_name.tr(" ", "+")}"
  end

  def inat_name_search_url(name)
    "https://www.inaturalist.org/search?q=#{name.text_name.tr(" ", "+")}"
  end

  def mushroomexpert_name_search_url(name)
    # Use DuckDuckGo see https://github.com/MushroomObserver/mushroom-observer/issues/1884#issuecomment-1950137454
    name_string = name.text_name.
                  sub(/ (group|clade)$/, "").
                  tr(" ", "+")
    "https://duckduckgo.com/?q=site%3Amushroomexpert.com+" \
    "%22#{name_string}%22&ia=web"
  end

  def mycoguide_name_search_url(name)
    "https://www.mycoguide.com/guide/search?q=#{name.text_name.tr(" ", "+")}"
  end

  def ncbi_nucleotide_term_search_url(name)
    "https://www.ncbi.nlm.nih.gov/nuccore/?term=#{name.text_name.tr(" ", "+")}"
  end

  def wikipedia_term_search_url(name)
    "https://en.wikipedia.org/w/index.php?search=#{name.text_name.tr(" ", "+")}"
  end

  # url for IF record
  def index_fungorum_record_url(record_id)
    "http://www.indexfungorum.org/Names/NamesRecord.asp?RecordID=#{record_id}"
  end

  # Use web search because IF internal search uses js form rather than a url
  def index_fungorum_name_search_url(name)
    # Use DuckDuckGo because the equivalent Google search results stink,
    # and Bing shows an annoying ChatBot thing
    # See https://github.com/MushroomObserver/mushroom-observer/issues/1884#issuecomment-1950137454
    name_string = name.text_name.
                  sub(/ (group|clade)$/, "").
                  tr(" ", "+")
    "https://duckduckgo.com/?q=site%3Aindexfungorum.org+" \
    "%22#{name_string}%22&ia=web"
  end

  # url for MB record by number
  def mycobank_record_url(record_id)
    "#{mycobank_host}/MB/#{record_id}"
  end

  # url for MycoBank name search for text_name
  def mycobank_name_search_url(name)
    "#{mycobank_basic_search_url}/field/Taxon%20name/#{
      name.text_name.gsub(" ", "%20")
    }"
  end

  def mycobank_basic_search_url
    "#{mycobank_host}page/Basic%20names%20search"
  end

  def mycobank_host
    "https://www.mycobank.org/"
  end

  # url for name search on MyCoPortal
  def mycoportal_url(name)
    "http://mycoportal.org/portal/taxa/index.php?taxauthid=1&taxon=" \
      "#{name.text_name.tr(" ", "+")}"
  end

  # url of SF page with "official" synonyms by category
  # works for species, infra-specific ranks
  def species_fungorum_gsd_synonymy(record_id)
    "http://www.speciesfungorum.org/Names/GSDspecies.asp?RecordID=#{record_id}"
  end

  # url of SF page with "official" synonyms in alpha order
  # works for species, genus, family
  def species_fungorum_sf_synonymy(record_id)
    "http://www.speciesfungorum.org/Names/SynSpecies.asp?RecordID=#{record_id}"
  end

  # ----------------------------------------------------------------------------

  # Wrap user name in link to show_user.
  #
  #   Owner:   <%= user_link(name.user) %>
  #   Authors: <%= name.authors.map(&:user_link).join(", ") %>
  #
  #   # If you don't have a full User instance handy:
  #   Modified by: <%= user_link(login, user_id) %>
  #
  def user_link(user, name = nil, args = {})
    if !user
      return "?"
    elsif user.is_a?(Integer)
      name ||= "#{:USER.t} ##{user}"
      user_id = user
    elsif user
      name ||= user.unique_text_name
      user_id = user.id
    end

    link_to(
      name, user_path(user_id),
      args.merge(
        { class: class_names("show_user_link_#{user_id}", args[:class]) }
      )
    )
  end

  # Render a list of users on one line.  (Renders nothing if user list empty.)
  # This renders the following strings:
  #
  #   <%= user_list("Author", name.authors) %>
  #
  #   empty:           ""
  #   [bob]:           "Author: Bob"
  #   [bob,fred,mary]: "Authors: Bob, Fred, Mary"
  #
  def user_list(title, users = [])
    return safe_empty unless users&.any?

    title = users.size > 1 ? title.to_s.pluralize.to_sym.t : title.t
    links = users.map { |u| user_link(u, u.legal_name) }
    # interpolating would require inefficient #sanitize
    # or dangerous #html_safe
    title + ": " + links.safe_join(", ")
  end

  # Wrap object's name in link to the object, return nil if no object
  #   Project: <%= project_link(draft_name.project) %>
  #   Species List: <%= species_list_link(observation.species_lists.first) %>
  def link_to_object(object, name = nil)
    return nil unless object

    unique_class = "show_#{object.type_tag}_link_#{object.id}"
    link_to(name || object.title.t, object.show_link_args,
            { id: unique_class })
  end

  # Wrap description title in link to show_description.
  #
  #   Description: <%= description_link(name.description) %>
  #
  def description_link(desc)
    result = description_title(desc)
    return result if result.match?("(#{:private.t})$")

    link_with_query(result, desc.show_link_args,
                    id: "show_description_link_#{desc.id}")
  end

  def observation_herbarium_record_link(obs)
    count = obs.herbarium_records.size
    if count.positive?

      link_to((count == 1 ? :herbarium_record.t : :herbarium_records.t),
              herbarium_records_path(observation_id: obs.id),
              { id: "herbarium_records_for_observation_link" })
    else
      return :show_observation_specimen_available.t if obs.specimen

      :show_observation_specimen_not_available.t
    end
  end
end
