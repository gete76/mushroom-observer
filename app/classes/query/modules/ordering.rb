# frozen_string_literal: true

module Query::Modules::Ordering
  def initialize_order
    by = params[:by]
    # Let queries define custom order spec in "order", but have explicitly
    # passed-in "by" parameter take precedence.  If neither is given, then
    # fall back on the "default_order" finally.
    return unless by || order.blank?

    by ||= default_order
    by = by.dup
    reverse = !!by.sub!(/^reverse_/, "")
    result = initialize_order_specs(by)
    self.order = reverse ? reverse_order(result) : result
  end

  def initialize_order_specs(by)
    sorting_method = "sort_by_#{by}"
    if ::Query::Modules::Ordering.method_defined?(sorting_method)
      send(sorting_method, model)
    else
      raise("Can't figure out how to sort #{model} by :#{by}.")
    end
  end

  def sort_by_updated_at(model)
    "#{model.table_name}.updated_at DESC" if model.column_names.include?("updated_at")
  end

  def sort_by_created_at(model)
    "#{model.table_name}.created_at DESC" if model.column_names.include?("created_at")
  end

  def sort_by_last_login(model)
    "#{model.table_name}.last_login DESC" if model.column_names.include?("last_login")
  end

  def sort_by_num_views(model)
    "#{model.table_name}.num_views DESC" if model.column_names.include?("num_views")
  end

  def sort_by_date(model)
    if model.column_names.include?("date")
      "#{model.table_name}.date DESC"
    elsif model.column_names.include?("when")
      "#{model.table_name}.when DESC"
    elsif model.column_names.include?("created_at")
      "#{model.table_name}.created_at DESC"
    end
  end

  def sort_by_name(model)
    case model.name
    when Image.name
      add_join(:observation_images, :observations)
      add_join(:observations, :names)
      self.group = "images.id"
      "MIN(names.sort_name) ASC, images.when DESC"
    when Location.name
      if User.current_location_format == "scientific"
        "locations.scientific_name ASC"
      else
        "locations.name ASC"
      end
    when LocationDescription.name
      add_join(:locations)
      "locations.name ASC, location_descriptions.created_at ASC"
    when Name.name
      "names.sort_name ASC"
    when NameDescription.name
      add_join(:names)
      "names.sort_name ASC, name_descriptions.created_at ASC"
    when Observation.name
      add_join(:names)
      "names.sort_name ASC, observations.when DESC"
    else
      if model.column_names.include?("sort_name")
        "#{model.table_name}.sort_name ASC"
      elsif model.column_names.include?("name")
        "#{model.table_name}.name ASC"
      elsif model.column_names.include?("title")
        "#{model.table_name}.title ASC"
      end
    end
  end

  def sort_by_title(model)
    "#{model.table_name}.title ASC" if model.column_names.include?("title")
  end

  def sort_by_login(model)
    "#{model.table_name}.login ASC" if model.column_names.include?("login")
  end

  def sort_by_summary(model)
    "#{model.table_name}.summary ASC" if model.column_names.include?("summary")
  end

  def sort_by_copyright_holder(model)
    "#{model.table_name}.copyright_holder ASC" if model.column_names.include?("copyright_holder")
  end

  def sort_by_where(model)
    "#{model.table_name}.where ASC" if model.column_names.include?("where")
  end

  def sort_by_initial_det(model)
    "#{model.table_name}.initial_det ASC" if model.column_names.include?("initial_det")
  end

  def sort_by_accession_number(model)
    "#(model.table_name}.accession_number ASC" if model.column_names.include?("accession_number")
  end

  def sort_by_user(model)
    if model.column_names.include?("user_id") || model == Herbarium
      add_join(:users)
      'IF(users.name = "" OR users.name IS NULL, users.login, users.name) ASC'
    end
  end

  def sort_by_location(model)
    if model.column_names.include?("location_id")
      # Join Users with null locations, else join records with locations
      model == User ? add_join(:locations!) : add_join(:locations)
      if User.current_location_format == "scientific"
        "locations.scientific_name ASC"
      else
        "locations.name ASC"
      end
    end
  end

  def sort_by_rss_log(model)
    if model.column_names.include?("rss_log_id")
      add_join(:rss_logs)
      "rss_logs.updated_at DESC"
    end
  end

  def sort_by_confidence(model)
    if model == Image
      add_join(:observation_images, :observations)
      "observations.vote_cache DESC"
    elsif model == Observation
      "observations.vote_cache DESC"
    end
  end

  def sort_by_image_quality(model)
    "images.vote_cache DESC" if model == Image
  end

  def sort_by_thumbnail_quality(model)
    if model == Observation
      add_join(:"images.thumb_image")
      "images.vote_cache DESC, observations.vote_cache DESC"
    end
  end

  def sort_by_owners_quality(model)
    if model == Image
      add_join(:image_votes)
      where << "image_votes.user_id = images.user_id"
      "image_votes.value DESC"
    end
  end

  def sort_by_owners_thumbnail_quality(model)
    if model == Observation
      add_join(:"images.thumb_image", :image_votes)
      where << "images.user_id = observations.user_id"
      where << "image_votes.user_id = observations.user_id"
      "image_votes.value DESC, " \
      "images.vote_cache DESC, " \
      "observations.vote_cache DESC"
    end
  end

  def sort_by_observation(model)
    "observation_id DESC" if model.column_names.include?("observation_id")
  end

  def sort_by_contribution(model)
    "users.contribution DESC" if model == User
  end

  def sort_by_original_name(model)
    "images.original_name ASC" if model == Image
  end

  def sort_by_url(model)
    "external_links.url ASC" if model == ExternalLink
  end

  def sort_by_herbarium_name(_model)
    add_join(:herbaria)
    "herbaria.name ASC"
  end

  def sort_by_herbarium_label(_model)
    "herbarium_records.initial_det ASC, " \
    "herbarium_records.accession_number ASC"
  end

  def sort_by_name_and_number(_model)
    "collection_numbers.name ASC, collection_numbers.number ASC"
  end

  def sort_by_code(_model)
    where << "herbaria.code != ''"
    "herbaria.code ASC"
  end

  def sort_by_code_then_name(_model)
    "IF(herbaria.code = '', '~', herbaria.code) ASC, herbaria.name ASC"
  end

  def sort_by_records(_model)
    # outer_join needed to show herbaria with no records
    add_join(:herbarium_records!)
    self.group = "herbaria.id"
    "count(herbarium_records.id) DESC"
  end

  def sort_by_id(model) # (for testing)
    "#{model.table_name}.id ASC"
  end

  def reverse_order(order)
    order.gsub(/(\s)(ASC|DESC)(,|\Z)/) do
      Regexp.last_match(1) +
        (Regexp.last_match(2) == "ASC" ? "DESC" : "ASC") +
        Regexp.last_match(3)
    end
  end
end
