# frozen_string_literal: true

#  Controller for nucleotide Sequences
#
#  Actions:
#
#    create::   Create new sequence and add to Observation
#    destroy::  Destroy sequence
#    edit::     Show form to edit a Sequence
#    new::      Show form to create new Sequence for an Observation
#    index::    List selected Sequences, based on index flavor and current Query
#    show::     Display Sequence details
#    update::   Update a Sequence
#
# Table: (updated 2022-08-17)
# legacy Sequence action (method)   updated Sequences action (method)
# * == legacy action not redirected
# --------------------------------  ---------------------------------
# create_sequence (get)             new (get)
# *create_sequence (post)           create (post)
# destroy_sequence (delete)         destroy (delete)
# edit_sequence (get)               edit (get)
# *edit_sequence (post)             update (patch)
# index_sequence (get)              index (get) -- lists query results
# list_sequences (get)              index (get, flavor: all) -- all Sequences
# *next_sequence (get)              show { flow: :next } (get))
# *prev_sequence (get)              show { flow: :prev } (get)
# *observation_index (get)          n.a (unused, listed Seqs for one Obs)
# *sequence_search (get)            n.a (unused, listed Seqs matching Pattern)
# show_sequence (get)               show (get)
#
class SequencesController < ApplicationController
  before_action :login_required
  before_action :store_location, only: [:create, :edit, :new, :show, :update]
  before_action :pass_query_params, only: [
    :create, :destroy, :edit, :new, :show, :update
  ]

  ################# Actions that show data without modifying it

  # display a list of Sequences, depending on flavor & params
  # Example:
  #  https://mushroomobserver.org/sequences?flavor=all
  #    => displays a list of all sequences in MO
  #
  def index
    case params[:flavor]
    when "all"
      index_all
    else
      query = find_or_create_query(:Sequence, by: params[:by])
      show_selected_sequences(query, id: params[:id].to_s, always_index: true)
    end
  end

  def show
    case params[:flow]
    when "next"
      redirect_to_next_object(:next, Sequence, params[:id]) and return
    when "prev"
      redirect_to_next_object(:prev, Sequence, params[:id]) and return
    end

    @sequence = find_or_goto_index(Sequence, params[:id].to_s)
  end

  ################# Actions that modify data

  def new
    # Observation.id is passed as a query param (rather than route :id param)
    # in order to give :id param a consistent meaning (the sequence id)
    # in this controller and in order to avoid an extra, non-standard route
    return if params[:observation_id].blank?

    return unless find_observation!

    @sequence = Sequence.new

    respond_to do |format|
      format.html
      format.js do
        render_modal_sequence_form(
          title: helpers.sequence_form_new_title
        )
      end
    end
  end

  def create
    return unless find_observation!

    build_sequence
  end

  def edit
    return unless find_sequence!

    figure_out_where_to_go_back_to
    return unless make_sure_can_edit!(@sequence)

    respond_to do |format|
      format.html
      format.js do
        render_modal_sequence_form(
          title: helpers.sequence_form_edit_title(seq: @sequence)
        )
      end
    end
  end

  def update
    return unless find_sequence!

    figure_out_where_to_go_back_to
    return unless make_sure_can_edit!(@sequence)

    save_edits
  end

  def destroy
    @sequence = find_or_goto_index(Sequence, params[:id].to_s)
    return unless @sequence

    figure_out_where_to_go_back_to
    return unless make_sure_can_delete!(@sequence)

    @observation = @sequence.observation # needed for js to update obs page

    @sequence.destroy
    flash_notice(:runtime_destroyed_id.t(type: :sequence, value: params[:id]))
    show_flash_and_send_to_back_object
  end

  ##############################################################################

  private

  def find_observation!
    @observation = Observation.includes(observation_includes).
                   find_by(id: params[:observation_id]) ||
                   flash_error_and_goto_index(
                     Observation, params[:observation_id]
                   )
  end

  def observation_includes
    [:user, { thumb_image: [:image_votes, :license, :projects, :user] }]
    # for matrix_box_carousels:
    # [:user, { images: [:image_votes, :license, :projects, :user] }]
  end

  def find_sequence!
    @sequence = Sequence.includes(sequence_includes).find_by(id: params[:id]) ||
                flash_error_and_goto_index(
                  Sequence, params[:id]
                )
  end

  def sequence_includes
    [{ observation:
       { thumb_image: [:image_votes, :license, :projects, :user] } }]
    # for matrix_box_carousels:
    # [{ observation: { images: [:image_votes, :license, :projects, :user] } }]
  end

  def figure_out_where_to_go_back_to
    @back = params[:back]
    @back_object = @back == "show" ? @sequence : @sequence.observation
  end

  def render_modal_sequence_form(title:)
    render(partial: "shared/modal_form_show",
           locals: { title: title, identifier: "sequence" }) and return
  end

  def render_sequences_section_update
    render(
      partial: "observations/show/section_update",
      locals: { identifier: "sequences" }
    ) and return
  end

  def render_modal_flash_update
    render(partial: "shared/modal_flash_update") and return
  end

  # ---------- Index -----------------------------------------------------------

  def index_all
    store_location
    query = create_query(:Sequence, :all)
    show_selected_sequences(query)
  end

  def show_selected_sequences(query, args = {})
    args = { include: [{ observation: :name }, :user],
             letters: "sequences.locus",
             num_per_page: 50 }.merge(args)
    show_index_of_objects(query, args)
  end

  # ---------- Create, Edit ----------------------------------------------------

  def make_sure_can_edit!(obj)
    return true if check_permission(obj)

    flash_warning(:permission_denied.t)
    show_flash_and_send_back
    false
  end

  def make_sure_can_delete!(sequence)
    return true if check_permission(sequence)

    flash_error(:permission_denied.t)
    show_flash_and_send_to_back_object
    false
  end

  # create
  def build_sequence
    @sequence = @observation.sequences.new
    @sequence.attributes = sequence_params
    @sequence.user = @user
    if @sequence.save
      flash_notice(:runtime_sequence_success.t(id: @sequence.id))
      respond_to_successful_form_submit
    else
      flash_object_errors(@sequence)
      respond_to_form_errors
    end
  end

  # update
  def save_edits
    @sequence.attributes = sequence_params
    if @sequence.save
      flash_notice(:runtime_sequence_update_success.t(id: @sequence.id))
      @observation = @sequence.observation # needed for js to update obs page
      respond_to_successful_form_submit
    else
      flash_object_errors(@sequence)
      respond_to_form_errors
    end
  end

  def respond_to_successful_form_submit
    redirect_to = case action_name
                  when "create"
                    @observation.show_link_args
                  when "update"
                    @back_object.show_link_args
                  end

    respond_to do |format|
      format.html do
        redirect_with_query(redirect_to)
      end
      format.js do
        render_sequences_section_update
      end
    end
  end

  def respond_to_form_errors
    redo_action = case action_name
                  when "create"
                    :new
                  when "update"
                    :edit
                  end
    respond_to do |format|
      format.html { render(action: redo_action) and return }
      format.js do
        render_modal_flash_update
      end
    end
  end

  def show_flash_and_send_back
    respond_to do |format|
      format.html do
        redirect_with_query(@sequence.observation.show_link_args) and
          return
      end
      format.js do
        render_modal_flash_update
      end
    end
  end

  def show_flash_and_send_to_back_object
    respond_to do |format|
      format.html do
        if @back == "index"
          redirect_with_query(action: :index)
        else
          redirect_with_query(@back_object.show_link_args)
        end
      end
      format.js do
        # renders the flash in the obs page via js
        render_sequences_section_update
      end
    end
  end

  # ---------- Strong Parameters -----------------------------------------------

  def sequence_params
    params[:sequence].permit(:archive, :accession, :bases, :locus, :notes)
  end
end
