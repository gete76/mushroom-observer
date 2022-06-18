# frozen_string_literal: true

class UsersController < ApplicationController
  # These need to be moved into the files where they are actually used.
  require "find"
  require "set"

  before_action :login_required
  before_action :disable_link_prefetching, except: [
    :show
  ]

  # User index, restricted to admins.
  def index
    if in_admin_mode? || find_query(:User)
      query = find_or_create_query(:User, by: params[:by])
      show_selected_users(query, id: params[:id].to_s, always_index: true)
    else
      flash_error(:runtime_search_has_expired.t)
      redirect_to(action: "list_rss_logs")
    end
  end

  alias index_user index
  # People guess this page name frequently for whatever reason, and
  # since there is a view with this name, it crashes each time.
  alias list_users index

  # User index, restricted to admins.
  def by_name
    if in_admin_mode?
      query = create_query(:User, :all, by: :name)
      show_selected_users(query)
    else
      flash_error(:permission_denied.t)
      redirect_to(action: "list_rss_logs")
    end
  end

  # Display list of User's whose name, notes, etc. match a string pattern.
  def user_search
    pattern = params[:pattern].to_s
    if pattern.match(/^\d+$/) &&
       (user = User.safe_find(pattern))
      redirect_to(action: "show", id: user.id)
    else
      query = create_query(:User, :pattern_search, pattern: pattern)
      show_selected_users(query)
    end
  end

  def show_selected_users(query, args = {})
    store_query_in_session(query)
    @links ||= []
    args = {
      action: "index",
      include: :user_groups,
      matrix: !in_admin_mode?
    }.merge(args)

    # Add some alternate sorting criteria.
    args[:sorting_links] = if in_admin_mode?
                             [
                               ["id",          :sort_by_id.t],
                               ["login",       :sort_by_login.t],
                               ["name",        :sort_by_name.t],
                               ["created_at",  :sort_by_created_at.t],
                               ["updated_at",  :sort_by_updated_at.t],
                               ["last_login",  :sort_by_last_login.t]
                             ]
                           else
                             [
                               ["login",         :sort_by_login.t],
                               ["name",          :sort_by_name.t],
                               ["created_at",    :sort_by_created_at.t],
                               ["location",      :sort_by_location.t],
                               ["contribution",  :sort_by_contribution.t]
                             ]
                           end

    # Paginate by "correct" letter.
    args[:letters] = if (query.params[:by] == "login") ||
                        (query.params[:by] == "reverse_login")
                       "users.login"
                     else
                       "users.name"
                     end

    show_index_of_objects(query, args)
  end

  # by_contribution.rhtml
  def by_contribution
    SiteData.new
    @users = User.by_contribution
  end

  # show.rhtml
  def show
    case params[:flow]
    when "next"
      redirect_to_next_object(:next, Herbarium, params[:id].to_s)
    when "prev"
      redirect_to_next_object(:prev, Herbarium, params[:id].to_s)

    store_location
    id = params[:id].to_s
    @show_user = find_or_goto_index(User, id)
    return unless @show_user

    @user_data = SiteData.new.get_user_data(id)
    @life_list = Checklist::ForUser.new(@show_user)
    @query = Query.lookup(:Observation, :by_user,
                          user: @show_user, by: :owners_thumbnail_quality)
    image_includes = { thumb_image: [:image_votes, :license, :user] }
    @observations = @query.results(limit: 6, include: image_includes)
    return unless @observations.length < 6

    @query = Query.lookup(:Observation, :by_user,
                          user: @show_user, by: :thumbnail_quality)
    @observations = @query.results(limit: 6, include: image_includes)
  end

  alias show_user show

  # Display a checklist of species seen by a User, Project,
  # SpeciesList or the entire site.
  def checklist
    store_location
    user_id = params[:user_id] || params[:id]
    proj_id = params[:project_id]
    list_id = params[:species_list_id]
    if user_id.present?
      if (@show_user = find_or_goto_index(User, user_id))
        @data = Checklist::ForUser.new(@show_user)
      end
    elsif proj_id.present?
      if (@project = find_or_goto_index(Project, proj_id))
        @data = Checklist::ForProject.new(@project)
      end
    elsif list_id.present?
      if (@species_list = find_or_goto_index(SpeciesList, list_id))
        @data = Checklist::ForSpeciesList.new(@species_list)
      end
    else
      @data = Checklist::ForSite.new
    end
  end
end
