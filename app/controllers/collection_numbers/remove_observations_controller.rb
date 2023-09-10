# frozen_string_literal: true

# Remove one observation from a collection number.
#
# Route: `collection_number_remove_observation_path`
# Only one action here. Call namespaced controller actions with a hash like
# `{ controller: "/collection_numbers/remove_observation", action: :update }`
module CollectionNumbers
  class RemoveObservationsController < ApplicationController
    before_action :login_required
    before_action :pass_query_params

    # The edit action exists just to present a dialog box explaining
    # what the action does, with a remove button (to the :update action)
    # Should only be hit by turbo_stream
    def edit
      init_ivars_for_edit
      return unless make_sure_can_delete!(@collection_number)

      render(
        partial: "shared/modal_form",
        locals: {
          title: nil,
          identifier: "collection_number_observation",
          form_partial: "collection_numbers/remove_observations/form"
        }
      ) and return
    end

    def update
      init_ivars_for_edit
      return unless make_sure_can_delete!(@collection_number)

      @collection_number.remove_observation(@observation)
      flash_notice(:runtime_removed.t(type: :collection_number))

      respond_to do |format|
        format.html do
          redirect_with_query(observation_path(@observation.id))
        end
        format.turbo_stream do
          render(
            partial: "observations/show/section_update",
            locals: { identifier: "collection_numbers" }
          ) and return
        end
      end
    end

    private

    # NOTE: find_or_goto_index involves a return, no need for "return unless"
    def init_ivars_for_edit
      @collection_number = find_or_goto_index(CollectionNumber,
                                              params[:collection_number_id])
      @observation = find_or_goto_index(Observation,
                                        params[:observation_id])
    end

    def make_sure_can_delete!(collection_number)
      return true if collection_number.can_edit? || in_admin_mode?

      flash_error(:permission_denied.t)
      redirect_to(collection_number_path(collection_number))
      false
    end
  end
end
