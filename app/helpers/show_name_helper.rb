# frozen_string_literal: true

# helpers for ShowName view and ShowNameInfo section of ShowObservation
module ShowNameHelper
  ######## links to queries of observations of name... or related taxa.
  # Counting these slows down the names#show page a LOT if done separately.
  # Counts now derived from `obss`, an instantiation of Name::Observations
  def name_related_taxa_observation_links(name, obss)
    [
      # Observations of this name
      tag.p(taxon_obss_this_name(name, obss) || "#{:obss_of_this_name.t} (0)"),
      # Observations of taxon under other names
      tag.p(taxon_obss_other_names(name, obss) ||
            "#{:taxon_obss_other_names.t} (0)"),
      # Observations of taxon under any name
      tag.p(taxon_obss_any_name(name, obss) || "#{:obss_of_taxon.t} (0)"),
      # Observations of other taxa where this taxon was proposed
      tag.p(taxon_proposed(name, obss) || "#{:obss_taxon_proposed.t} (0)"),
      # Observations where this Name was proposed
      tag.p(name_proposed(name, obss) || "#{:obss_name_proposed.t} (0)")
    ].safe_join
  end

  # link to a search for Observations of name and a count of those observations
  #   This Name (1)
  def taxon_obss_this_name(name, obss)
    link_to_obss_of(obss_of_taxon_this_name(name), :obss_of_this_name.t,
                    obss.of_taxon_this_name.size)
  end

  # link to a search for observations of this taxon, under other names + count
  def taxon_obss_other_names(name, obss)
    link_to_obss_of(obss_of_taxon_other_names(name), :taxon_obss_other_names.t,
                    obss.of_taxon_other_names.size)
  end

  # link to a search for Observations of this taxon (under any name) + count
  def taxon_obss_any_name(name, obss)
    link_to_obss_of(obss_of_taxon_any_name(name), :obss_of_taxon.t,
                    obss.of_taxon_any_name.size)
  end

  # link to a search for observations where this taxon was proposed + count
  # (but is not the consensus)
  def taxon_proposed(name, obss)
    link_to_obss_of(obss_other_taxa_this_taxon_proposed(name),
                    :obss_taxon_proposed.t, obss.where_taxon_proposed.size)
  end

  # link to a search for observations where this name was proposed
  def name_proposed(name, obss)
    link_to_obss_of(obss_this_name_proposed(name),
                    :obss_name_proposed.t, obss.where_name_proposed.size)
  end

  # return link to a query for observations + count of results
  # returns nil if no results
  # Use:
  #   query = Query.lookup(:Observation, :all, names: name.id, by: :confidence,
  #                        include_synonyms: true)
  #   link_to_obss_of(query, :obss_of_taxon.t)
  #   => <a href="/observations?q=Q">This Taxon, any name</a> (19)
  def link_to_obss_of(query, title, count)
    # count = query.select_count # This executes a query per link.
    return nil if count.zero?

    query.save
    link_to(
      title,
      add_query_param(observations_path, query)
    ) + " (#{count})"
  end

  ######## searches

  # These are extracted for isolation and to facilitate testing
  # These don't run queries... it's query.select_count above, that does.

  def obss_of_taxon_this_name(name)
    Query.lookup(:Observation, :all,
                 names: name.id,
                 by: :confidence)
  end

  def obss_of_taxon_other_names(name)
    Query.lookup(:Observation, :all,
                 names: name.id,
                 include_synonyms: true,
                 exclude_original_names: true,
                 by: :confidence)
  end

  def obss_of_taxon_any_name(name)
    Query.lookup(:Observation, :all,
                 names: name.id,
                 include_synonyms: true,
                 by: :confidence)
  end

  # These two do joins to Namings. Unbelievably, it's faster than the above?
  def obss_other_taxa_this_taxon_proposed(name)
    Query.lookup(:Observation, :all,
                 names: name.id,
                 include_synonyms: true,
                 include_all_name_proposals: true,
                 exclude_consensus: true,
                 by: :confidence)
  end

  def obss_this_name_proposed(name)
    Query.lookup(:Observation, :all,
                 names: name.id,
                 include_all_name_proposals: true,
                 by: :confidence)
  end
end
