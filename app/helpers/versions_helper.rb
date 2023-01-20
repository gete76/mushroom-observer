# frozen_string_literal: true

# helpers which create html which links to prior version(s)
module VersionsHelper
  # Just shows the current version number and a link to see the previous.
  #
  #   <%= show_previous_version(name) %>
  #
  #   # Renders just this:
  #   Version: N <br/>
  #   Previous Version: N-1<br/>
  #
  def show_previous_version(obj) # rubocop:disable Metrics/AbcSize
    html = :VERSION.t + ": " + obj.version.to_s
    latest_version = obj.versions.latest
    html += safe_br
    return html unless latest_version

    if (previous_version = latest_version.previous)
      str = :show_name_previous_version.t + " " + previous_version.version.to_i
      html += link_with_query(str,
                              controller: "#{obj.show_controller}/versions",
                              action: :show, id: obj.id,
                              version: previous_version.version)
      html += safe_br
    end
    html
  end

  # Show list of past versions for show_past_object pages.
  #
  #   <%= show_past_versions(name) %>
  #
  #   # Renders something like this:
  #   <p>
  #     Other Versions:<br/>
  #       N: Latest Name<br/>
  #       N-1: Previous Name<br/>
  #       ...
  #       1: Original Name<br/>
  #   </p>
  #
  def show_past_versions(obj, args = {}) # rubocop:disable Metrics/AbcSize
    versions = obj.versions.reverse
    table = versions.map do |ver|
      # Date change was made.
      date = find_ver_date(ver)

      # User making the change.
      user = find_ver_user(ver, user)

      # Version number (and name if available).
      link = "#{:VERSION.t} #{ver.version}"
      link += " #{ver.format_name.t}" if ver.respond_to?(:format_name)
      link = link_to_ver(link, ver, obj) if ver.version != obj.version
      link = content_tag(:b, link) if args[:bold]&.call(ver)

      i = indent
      [date, i, user, i, link, i]
    end

    table = make_table(table, class: "ml-4")
    tag.p(:VERSIONS.t) + table + safe_br
  end

  def find_ver_date(ver)
    ver.updated_at.web_date
  rescue StandardError
    :unknown.t
  end

  def find_ver_user(ver, user)
    if (user = User.safe_find(ver.user_id))
      user_link(user, user.login)
    else
      :unknown.t
    end
  end

  def link_to_ver(link, ver, obj)
    if ver == obj.versions.last
      link_with_query(link, controller: obj.show_controller,
                            action: obj.show_action,
                            id: obj.id)
    else
      link_with_query(link,
                      controller: "#{obj.show_controller}/versions",
                      action: :show, id: obj.id,
                      version: ver.version)
    end
  end
end
