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
      redirect_to(observer_list_rss_logs_path)
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
      redirect_to(observer_list_rss_logs_path)
    end
  end

  # Display list of User's whose name, notes, etc. match a string pattern.
  def user_search
    pattern = params[:pattern].to_s
    if pattern.match(/^\d+$/) &&
       (user = User.safe_find(pattern))
      redirect_to(user_path(user.id))
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
      redirect_to_next_object(:next, User, params[:id].to_s)
    when "prev"
      redirect_to_next_object(:prev, User, params[:id].to_s)
    else
      @user = find_or_goto_index(User, params[:id])
    end

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
end
