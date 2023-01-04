# frozen_string_literal: true

#  publish_description::       Publish a draft description.
module Locations::Descriptions
  class DraftsController < ApplicationController
    before_action :login_required
    before_action :disable_link_prefetching

    include ::Descriptions::Drafts
  end
end
