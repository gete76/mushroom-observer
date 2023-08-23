# frozen_string_literal: true

# --------- contextual nav ------------------------------------------------
#  --- links and buttons ----
#
#  add_page_title(title)        # add content_for(:title)
#                                 and content_for(:document_title)
#  title_tag_contents           # text to put in html header <title>
#  add_index_title              # logic for index titles, with fallbacks
#  index_default_title          # logic for observations index default sort
#  add_pager_for(object)        # add a prev/next pager for an object (show)
#  link_next                    # link to next object
#  link_prev                    # link to prev object
#  add_tab_set(links)           # add content_for(:tab_set)
#  create_links_to(links)       # convert links array -> link_to's / button_to's
#  create_link_to(link)         # convert one link attribute array into HTML
#  add_type_filters             # add content_for(:type_filters)
#  index_sorter                 # helper to render the sorter partial
#  add_interest_icons(user, object) # add content_for(:interest_icons)
#

module TitleAndTabsetHelper
  # sets both the html doc title and the title for the page (previously @title)
  def add_page_title(title)
    content_for(:title) do
      title
    end
    content_for(:document_title) do
      title_tag_contents(title)
    end
  end

  # contents of the <title> in html <head>
  def title_tag_contents(title, action: controller.action_name)
    if title.present?
      title.strip_html.unescape_html # removes tags and special chars
    elsif TranslationString.where(tag: "title_for_#{action}").present?
      :"title_for_#{action}".t
    else
      action.tr("_", " ").titleize
    end
  end

  # Special builder for index page titles.
  # These default to the query title, but may have several fallbacks, for
  # example, when users hit indexes with a bad or no query. The fallback
  # is determined by the "no_hits" arg. If indexes pass `no_hits: nil`,
  # the page will display the query title as the no_hits title.
  #
  # However, the helper allows indexes to pass a blank, non-nil `no_hits: ""`.
  # In this case, `index_default_title` will return a document_title of "Index"
  # but this helper will generate no title on the page. Currently this is the
  # expected behavior on Locations, Names, Observations and SpeciesLists tests.
  # It's debatable whether this is ideal UI, but i'm preserving the current
  # behavior for now.) - AN 2023
  def add_index_title(query, no_hits: nil)
    title = if !query
              ""
            elsif query.num_results.zero? && !no_hits.nil?
              no_hits
            else
              index_default_title(query)
            end
    add_page_title(title)
  end

  # Special title for new obs default home page query
  def index_default_title(query)
    if query.title_args[:type] == :observation &&
       query.title_args[:order] == :sort_by_rss_log
      return :query_title_observations_by_activity_log.l
    end

    query.title
  end

  # Used by several indexes that can be filtered based on user prefs
  def add_filter_help(filters_applied)
    return unless filters_applied

    content_for(:filter_help) do
      help_tooltip(
        "(#{:filtered.t})",
        title: :rss_filtered_mouseover.t, class: "filter-help"
      )
    end
  end

  # Show obs: observer's preferred naming. HTML here in case there is no naming
  def add_owner_naming(naming)
    return unless naming

    content_for(:owner_naming) do
      tag.h5(naming, id: "owner_naming")
    end
  end

  # Previous/next object links for show templates
  def add_pager_for(object)
    content_for(:prev_next_object) do
      render(partial: "application/content/prev_next_pager",
             locals: { object: object })
    end
  end

  # used by application/content/prev_next_pager
  # link to next object in query results
  def link_next(object)
    path = if object.type_tag == :rss_log
             send(:activity_log_path, object.id, flow: "next")
           else
             send("#{object.type_tag}_path", object.id, flow: "next")
           end
    link_with_query("#{:FORWARD.t} »", path)
  end

  # link to previous object in query results
  def link_prev(object)
    path = if object.type_tag == :rss_log
             send(:activity_log_path, object.id, flow: "prev")
           else
             send("#{object.type_tag}_path", object.id, flow: "prev")
           end
    link_with_query("« #{:BACK.t}", path)
  end

  # Short-hand to render shared tab_set partial for a given set of links.
  def add_tab_set(links)
    return unless links

    tabs = create_links_to(links)

    content_for(:tab_set) do
      render(partial: "application/content/tab_set", locals: { tabs: tabs })
    end
  end

  # Convert an array (of arrays) of link attributes into an array of HTML tabs
  # that may be either links or CRUD button_to's, for RHS tab set
  # Example
  # links = [
  #   ["text", "url", { class: "edit_form_link" }],
  #   [nil, article, { button: :destroy }]
  # ]
  # create_links_to(links) will make an array of the following HTML
  #   "<a href="url" class="edit_form_link">text</a>",
  #   "(an HTML form)" via destroy_button, gives default button text and class
  #
  # Allows passing an extra_args hash to be merged with each link's args
  #
  def create_links_to(links, extra_args = {})
    return [] unless links

    links.compact.map do |link|
      create_link_to(link, extra_args)
    end
  end

  # Unpacks the [text, url, args] array for a single link and figures out
  # which HTML to return for that type of link
  # Pass extra_args hash to modify the link/button attributes
  #
  def create_link_to(link, extra_args = {})
    str, url, args = link
    args ||= {}
    kwargs = merge_link_args_with_extra_args(args, extra_args)

    case args[:button]
    when :destroy
      destroy_button(name: str, target: args[:target] || url, **kwargs)
    when :post
      post_button(name: str, path: url, **kwargs)
    when :put
      put_button(name: str, path: url, **kwargs)
    when :patch
      patch_button(name: str, path: url, **kwargs)
    else
      link_to(str, url, kwargs)
    end
  end

  # Make a hash of the kwargs that will be passed to link helper for HTML.
  # e.g. { data: { pileus: "awesome" }, id: "best_pileus", class: "hidden" }
  # Removes args used in link_to/button helpers and merges with passed
  # extra_args, e.g. removes { name: "Click here to post", target: obs }
  # Note that class_names need to be concatenated or the merge will overwrite.
  #
  def merge_link_args_with_extra_args(args, extra_args)
    kwargs = args&.except(:button, :target)
    # blend in the class names that may come from the extra_args
    kwargs[:class] = class_names(kwargs[:class], extra_args[:class])
    # merge in other args from extra_args (will overwrite keys!)
    kwargs&.merge(extra_args&.except(:class))
  end

  # New style dropdown tabsets take array of tabs as hash of args,
  #   { name:, link:, class:, id:, etc. }
  #   not fully-formed `link_to` or `link_with_query`
  def add_dropdown_tab_set(links:, title: :LINKS.t)
    content_for(:dropdown_tab_set) do
      render(partial: "application/content/dropdown_tab_set",
             locals: { title: title, tabs: create_dropdown_tabs(links) })
    end
  end

  def create_dropdown_tabs(links)
    xtrargs = {
      role: "menuitem",
      class: "dropdown-item"
    }
    create_tabs(links, xtrargs)
  end

  def dropdown_link_options(args = {})
    args&.except(:name, :link, :button, :class) # prolly delete name and link
  end

  # type_filters, currently only used in RssLogsController#index
  def add_type_filters
    content_for(:type_filters) do
      render(partial: "application/content/type_filters")
    end
  end

  # The "Everything" tab
  def filter_for_everything(types)
    label = :rss_all.t
    link = activity_logs_path(params: { type: :all })
    help = { title: :rss_all_help.t, class: "filter-only" }
    types == ["all"] ? label : link_with_query(label, link, **help)
  end

  # A single tab
  def filter_for_type(types, type)
    label = :"rss_one_#{type}".t
    link = activity_logs_path(params: { type: type })
    help = { title: :rss_one_help.t(type: type.to_sym), class: "filter-only" }
    types == [type] ? label : link_with_query(label, link, **help)
  end

  # Sort links, for indexes
  def add_sorter(query, links, link_all: false)
    content_for(:sorter) do
      if links && (query&.num_results&.> 1)
        sorts = create_sorting_links(query, links, link_all)

        render(partial: "application/content/sorter", locals: { sorts: sorts })
      else
        ""
      end
    end
  end

  # Create sorting links, "graying-out" the current order.
  # Need query to know which is current order
  def create_sorting_links(query, links, link_all)
    results = []
    this_by = (query.params[:by] || query.default_order).sub(/^reverse_/, "")

    links.each do |by, label|
      results << link_or_grayed_text(link_all, this_by, label, query, by)
    end

    # Add a "reverse" button.
    results << sort_link(:sort_by_reverse.t, query, reverse_by(query, this_by))
  end

  def link_or_grayed_text(link_all, this_by, label, query, by)
    if !link_all && (by.to_s == this_by)
      [label.t, nil] # just text
    else
      sort_link(label.t, query, by)
    end
  end

  def sort_link(text, query, by)
    [text, { controller: query.model.show_controller,
             action: query.model.index_action,
             by: by }.merge(query_params)]
  end

  def reverse_by(query, this_by)
    if query.params[:by].to_s.start_with?("reverse_")
      this_by
    else
      "reverse_#{this_by}"
    end
  end

  # Draw the cutesy eye icons in the upper right side of screen.  It does it
  # by creating a "right" tab set.  Thus this must be called in the header of
  # the view and must not actually be rendered.  Typical usage would be:
  #
  #   # At top of view:
  #   <%
  #     # Specify the page's title.
  #     @title = "Page Title"
  #     add_interest_icons(@user, @object)
  #   %>
  #
  # This will cause the set of three icons to be rendered floating in the
  # top-right corner of the content portion of the page.

  def add_interest_icons(user, object)
    return unless user

    img1, img2, img3 = img_link_array(user, object)

    content_for(:interest_icons) do
      tag.div(img1 + safe_br + img2 + img3, class: "interest-eyes")
    end
  end

  # Array of image links which user can click to control getting email re object
  def img_link_array(user, object)
    type = object.type_tag
    case user.interest_in(object)
    when :watching
      img_links_when_watching(object, type)
    when :ignoring
      img_links_when_ignoring(object, type)
    else
      img_links_default(object, type)
    end
  end

  def img_links_when_watching(object, type)
    alt1 = :interest_watching.l(object: type.l)
    alt2 = :interest_default_help.l(object: type.l)
    alt3 = :interest_ignore_help.l(object: type.l)
    img1 = interest_icon_big("watch", alt1)
    img2 = interest_icon_small("halfopen", alt2)
    img3 = interest_icon_small("ignore", alt3)
    img2 = interest_link(img2, object, 0)
    img3 = interest_link(img3, object, -1)
    [img1, img2, img3]
  end

  def img_links_when_ignoring(object, type)
    alt1 = :interest_ignoring.l(object: type.l)
    alt2 = :interest_watch_help.l(object: type.l)
    alt3 = :interest_default_help.l(object: type.l)
    img1 = interest_icon_big("ignore", alt1)
    img2 = interest_icon_small("watch", alt2)
    img3 = interest_icon_small("halfopen", alt3)
    img2 = interest_link(img2, object, 1)
    img3 = interest_link(img3, object, 0)
    [img1, img2, img3]
  end

  def img_links_default(object, type)
    alt1 = :interest_watch_help.l(object: type.l)
    alt2 = :interest_ignore_help.l(object: type.l)
    img1 = interest_icon_small("watch", alt1)
    img2 = interest_icon_small("ignore", alt2)
    img1 = interest_link(img1, object, 1)
    img2 = interest_link(img2, object, -1)
    img3 = ""
    [img1, img2, img3]
  end

  # Create link to change interest state.
  def interest_link(label, object, state) # :nodoc:
    link_with_query(label, set_interest_path(id: object.id,
                                             type: object.class.name,
                                             state: state))
  end

  # Create large icon image.
  def interest_icon_big(type, alt) # :nodoc:
    image_tag("#{type}2.png", alt: alt, class: "interest_big", title: alt)
  end

  # Create small icon image.
  def interest_icon_small(type, alt) # :nodoc:
    image_tag("#{type}3.png", alt: alt, class: "interest_small", title: alt)
  end
end
