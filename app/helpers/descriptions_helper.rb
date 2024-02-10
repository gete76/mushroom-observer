# frozen_string_literal: true

module DescriptionsHelper
  include Tabs::DescriptionsHelper

  def writer?(desc)
    desc.writer?(User.current) || in_admin_mode?
  end

  def is_admin?(desc)
    desc.is_admin?(User.current) || in_admin_mode?
  end

  def reader?(desc)
    desc.is_reader?(User.current) || in_admin_mode?
  end

  # Header of the embedded description within a show_object page.
  #
  #   <%= show_embedded_description_title(desc, name) %>
  #
  #   # Renders something like this:
  #   <p>EOL Project Draft: Show | Edit | Destroy</p>
  #
  def show_embedded_description_title(desc, type)
    title = description_title(desc)
    links = description_mod_links(desc, type)
    tag.div do
      [tag.span(title, class: "text-lg"),
       links.safe_join(" | ")].safe_join(safe_nbsp)
    end
  end

  def description_mod_links(desc, type)
    links = []
    (text, path, args) = *edit_description_tab(desc, type)
    links << icon_link_to(text, path, **args) if writer?(desc)
    links << destroy_button(target: desc, icon: :delete) if is_admin?(desc)
    links
  end

  # Show list of name/location descriptions.
  def list_descriptions(object:, type:, fake_default: false)
    user = User.current
    # Filter out empty descriptions (unless it's public or one you own).
    list = object.descriptions.includes(:user).select do |desc|
      desc.notes? || (desc.user == user) ||
        reviewer? || (desc.source_type == :public) || in_admin_mode?
    end

    list = sort_description_list(object, list)

    make_list_links(list, type, fake_default)
  end

  # Sort, putting the default one on top, followed by public ones, followed
  # by others ending in personal ones, sorting by "length" among groups.
  def sort_description_list(object, list)
    type_order = Description.all_source_types
    list.sort_by! do |x|
      [
        (x.id == object.description_id ? 0 : 1),
        type_order.index(x.source_type),
        -x.note_status[0],
        -x.note_status[1],
        description_title(x),
        x.id
      ]
    end

    list
  end

  # Turn each into a link to show_description, and add optional controls.
  def make_list_links(list, type, fake_default)
    list.map! do |desc|
      item = description_link(desc)
      links = description_mod_links(desc, type)
      item += indent + "[ " + links.safe_join(" | ") + " ]" if links.any?
      item
    end

    # Add "fake" default public description if there aren't any public ones.
    if fake_default && obj.descriptions.none? { |d| d.source_type == :public }
      str = :description_part_title_public.t
      link = link_to(*create_description_tab(obj))
      str += indent + "[ " + link + " ]"
      list.unshift(str)
    end

    list
  end

  # Details of a description for a show_description page.
  def show_description_details(description, versions, user = User.current)
    type = description.parent.type_tag

    read = if description.reader_groups.include?(UserGroup.all_users)
             :public.t
           elsif in_admin_mode? || description.is_reader?(user)
             :restricted.t
           else
             :private.t
           end

    write = if description.writer_groups.include?(UserGroup.all_users)
              :public.t
            elsif in_admin_mode? || description.writer?(user)
              :restricted.t
            else
              :private.t
            end

    tag.div do
      [
        ["#{:TITLE.t}:", description_title(description)].safe_join(" "),
        ["#{type.to_s.upcase.to_sym.t}:",
         description.parent.format_name.t].safe_join(" "),
        "#{:show_description_read_permissions.t}: #{read}",
        "#{:show_description_write_permissions.t}: #{write}",
        show_previous_version(description, versions)
      ].safe_join(safe_br)
    end
  end

  def show_description_export_and_review(desc)
    capture do
      concat(tag.div(show_description_export_status(desc)))
      concat(tag.div(show_name_description_review(desc)))
    end
  end

  def show_description_export_status(desc)
    reviewer? ? export_status_controls(desc) : ""
  end

  def show_name_description_review(desc)
    return unless desc.parent.type_tag == :name

    html = []
    html << show_name_description_review_status(desc)
    html << show_name_description_latest_review(desc) if desc.reviewer
    html.safe_join
  end

  def show_name_description_review_status(desc)
    tag.div do
      concat("#{:show_name_content_status.l}: ")
      concat(review_as_string(desc.review_status))
      concat(show_name_description_review_ui(desc))
    end
  end

  def show_name_description_review_ui(desc)
    return unless reviewer?

    tag.span(class: "ml-3") do
      %w[unvetted vetted inaccurate].map do |w|
        put_button(
          name: :"review_#{w}".l,
          path: name_description_review_status_path(
            desc.id, value: w, q: get_query_param
          )
        )
      end.safe_join(tag.span(" | "))
    end
  end

  def show_name_description_latest_review(desc)
    tag.span(class: "help-note") do
      indent + "(" + :show_name_latest_review.t(
        date: desc.last_review ? desc.last_review.web_time : :UNKNOWN.t,
        user: user_link(desc.reviewer, desc.reviewer.login)
      ) + ")"
    end
  end

  # Show list of alternate descriptions for show_object page.
  #
  #   <%= show_alt_descriptions(object: name, projects: projects) %>
  #
  #   # Renders something like this:
  #   <p>
  #     Alternate Descriptions: Create Your Own
  #       Main Description
  #       EOL Project Draft
  #       Rolf's Draft (private)
  #   </p>
  #
  #   <p>
  #     Create New Draft For:
  #       Another Project
  #       One More Project
  #   </p>
  #
  def show_alt_descriptions(object:, projects: nil)
    type = object.type_tag

    # Show existing drafts, with link to create new one.
    head = tag.b(:show_name_descriptions.t) + ": "
    head += link_to(*create_description_tab(object, type))

    # Add title and maybe "no descriptions", wrapping it all up in paragraph.
    list = list_descriptions(object: object, type: type).map do |link|
      indent + link
    end
    any = list.any?
    list.unshift(head)
    list << indent + :"show_#{type}_no_descriptions".t unless any
    html = list.safe_join(safe_br)
    html = tag.div(html)

    add_list_of_projects(object, type, html, projects) if projects.present?
    html
  end

  # Show list of projects user is a member of.
  def add_list_of_projects(object, type, html, projects)
    return if projects.blank?

    head2 = :show_name_create_draft.t + ": "
    list = [head2] + projects.map do |project|
      item = link_to(*new_description_for_project_tab(object, type, project))
      indent + item
    end
    html2 = list.safe_join(safe_br)
    html += tag.p(html2)
    html
  end

  # Loops through all notes and returns a panel with heading for each note field
  def show_description_notes_all(desc)
    model = desc.type_tag.to_s.camelize.constantize
    type = desc.parent.type_tag
    Textile.register_name(desc.name) if type == :name

    any_notes = false
    model.all_note_fields.map do |field|
      value = desc.send(field).to_s
      next unless value.match?(/\S/)

      any_notes = true
      concat(
        panel_block(heading: :"form_#{type}s_#{field}".l) do
          value.tpl
        end
      )
    end

    :show_description_empty.tpl unless any_notes
  end

  def show_description_authors_and_editors(desc, versions, user = User.current)
    tag.div(class: "text-center") do
      concat(
        show_authors_and_editors(obj: desc, versions: versions, user: user)
      )
      if desc.license
        concat(render(partial: "shared/form_#{desc.license.form_name}"))
      end
    end
  end

  # Create a div for notes in Description subclasses.
  #
  #   <%= notes_panel(html) %>
  #
  #   <% notes_panel() do %>
  #     Render stuff in here.  Note lack of "=" in line above.
  #   <% end %>
  #
  def notes_panel(msg = nil, &block)
    msg = capture(&block) if block
    result = tag.div(msg, class: "panel-body")
    wrapper = tag.div(result, class: "panel panel-default dotted-border")
    if block
      concat(wrapper)
    else
      wrapper
    end
  end

  # Create a descriptive title for a Description.  Indicates the source and
  # very rough permissions (e.g. "public", "restricted", or "private").
  def description_title(desc)
    result = desc.partial_format_name

    # Indicate rough permissions.
    permit = if desc.parent.description_id == desc.id
               :default.l
             elsif desc.public
               :public.l
             elsif reader?(desc)
               :restricted.l
             else
               :private.l
             end
    result += " (#{permit})" unless /(^| )#{permit}( |$)/i.match?(result)

    t(result)
  end

  # Helpers for description forms

  # Source type options for description forms.
  def source_type_options_all
    options = []
    Description.all_source_types.each do |type|
      options << [:"form_description_source_#{type}".l, type]
    end
    options
  end

  def source_type_options_basic
    options = []
    Description.basic_source_types.each do |type|
      options << [:"form_description_source_#{type}".l, type]
    end
    options
  end
end
