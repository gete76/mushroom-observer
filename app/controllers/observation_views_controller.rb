# frozen_string_literal: true

class ObservationViewsController < ApplicationController
  before_action :login_required

  # endpoint to mark an observation as 'reviewed' by the current user
  def update
    pass_query_params
    # basic sanitizing of the param. ivars needed in js response
    # checked is a string!
    @reviewed = params[:reviewed] == "1"
    @obs_id = params[:id].to_s
    ov = ObservationView.update_view_stats(@obs_id, User.current_id)

    ov.update(reviewed: @reviewed)
    respond_to do |format|
      format.js
    end
  end
end
