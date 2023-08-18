# frozen_string_literal: true

#  move_descriptions::          Move a description to another parent.
module Locations::Descriptions
  class MovesController < ApplicationController
    before_action :login_required
    before_action :pass_query_params

    include ::Descriptions::Moves
    include ::Locations::Descriptions::SharedPrivateMethods
  end
end
