# frozen_string_literal: true

#
#  = Species List Model
#
#  A SpeciesList is a list of Observations (*not* Names's).  Various User's
#  have used them -- among other things -- to:
#
#  1. Gather all the Observation's at a given Location or region.
#  2. Gather all the Observation's of a loose taxonomic group.
#  3. Bulk-post Observation's from a mushroom foray.
#
#  Since no specific purpose was intended, SpeciesList's have a number of
#  attributes with no set meaning: +when+, +where+, +title+, +notes+.  The User
#  can choose any value for any of these.  The only ones that has any use are
#  +when+ and +where+, which are used as the defaults for new Observation's
#  created specifically for this SpeciesList.
#
#  *NOTE*: Observation's may belong to more than one SpeciesList.  Also note
#  that Observation's created by a SpeciesList are fairly minimal: they are all
#  created with the same date, location, and (optionally) notes, and they all
#  get a single Naming without any Vote's.
#
#  == Location
#
#  A SpeciesList can belong to either a defined Location (+location+, a
#  Location instance) or an undefined one (+where+, just a String), but not
#  both.  To make this a little easier, you can refer to +place_name+ instead,
#  which returns the name of whichever is present.
#
#  == Attributes
#
#  id::                    Locally unique numerical id, starting at 1.
#  created_at::            Date/time it was first created.
#  updated_at::            Date/time it was last updated.
#  user::                  User that created it.
#  when::                  Date -- meaning is up to User.
#  where::                 Location name -- meaning is up to User.
#  title::                 Title.
#  notes::                 Random notes.
#
#  ==== "Fake" attributes
#  file::                  Upload text file into +data+.
#  data::                  Internal temporary data field.
#  place_name::            Wrapper on top of +where+ and +location+.
#                          Handles location_format.
#
#  == Class methods
#
#  define_a_location::     Update any lists using the old "where" name.
#  ---
#  notes_part_id::         id of view textarea for a member notes heading
#  notes_area_id_prefix::  prefix for id of textarea
#  notes_part_name::       name of view textarea for a member notes heading
#
#  == Instance methods
#
#  text_name::             Return plain text title.
#  format_name::           Return formatted title.
#  unique_text_name::      (same thing, with id tacked on to make unique)
#  unique_format_name::    (same thing, with id tacked on to make unique)
#  ---
#  observations::          List of Observation's attached to it.
#  names::                 Get sorted list of Names used by its Observation's.
#  name_included::         Does this list include the given Name?
#  ---
#  form_notes_parts::      Array of member note parts for create & edit form
#  notes_part_id::         id of textarea for a member notes heading
#  notes_part_name::       name of textarea for a member notes heading
#  ---
#  process_file_data::     Process uploaded file according to one of
#                          the following two methods.
#  process_simple_list::   Process simple lists.
#  process_name_list::     Process lists generated by name list program(??)
#  construct_observation:: Create and add Observation to list.
#
#  == Callbacks
#
#  add_obs_callback::      Update User contribution when adding Observation's.
#  remove_obs_callback::   Update User contribution when removing Observation's.
#  log_destruction::       Log destruction after destroy.
#
################################################################################
#
class SpeciesList < AbstractModel
  require "arel-helpers"
  include ArelHelpers::ArelTable

  belongs_to :location
  belongs_to :rss_log
  belongs_to :user

  has_and_belongs_to_many :projects
  has_and_belongs_to_many :observations, after_add: :add_obs_callback,
                                         before_remove: :remove_obs_callback

  has_many :comments,  as: :target, dependent: :destroy
  has_many :interests, as: :target, dependent: :destroy

  attr_accessor :data

  # Automatically (but silently) log destruction.
  self.autolog_events = [:destroyed]

  # Callback that updates User contribution when adding Observation's.
  def add_obs_callback(_obs)
    SiteData.update_contribution(:add, :species_list_entries, user_id)
  end

  # Callback that updates User contribution when removing Observation's.
  def remove_obs_callback(_obs)
    SiteData.update_contribution(:del, :species_list_entries, user_id)
  end

  def self.find_by_title_with_wildcards(str)
    find_using_wildcards("title", str)
  end

  def clear
    num = observations.count
    SiteData.update_contribution(:del, :species_list_entries, user_id, num)

    # "observations.delete_all" is very similar, however it requires loading
    # all of the observations (and not just their ids).  Note also that we
    # would still have to update the user's contribution anyway.

    # Nimmo Note: afaik, we cannot yet use AR delete_all here because the
    # observations_species_lists table is not backed by a model
    # (i.e., it's has_and_belongs_to_many vs. has_many_through)
    # Conversion to HMT is possible but not super-simple.
    # SpeciesList.connection.delete(%(
    #   DELETE FROM observations_species_lists
    #   WHERE species_list_id = #{id}
    # ))
    delete_manager = arel_delete_observations_species_lists(id)
    # puts(delete_manager.to_sql)
    SpeciesList.connection.delete(delete_manager.to_sql)
  end

  def arel_delete_observations_species_lists(id)
    osl = Arel::Table.new(:observations_species_lists)
    Arel::DeleteManager.new.
      from(osl).
      where(osl[:species_list_id].eq(id))
  end

  ##############################################################################
  #
  #  :section: Names
  #
  ##############################################################################

  # Abstraction over +where+ and +location.display_name+.  Returns Location
  # name as a string, preferring +location+ over +where+ wherever both exist.
  # Also applies the location_format of the current user (defaults to :postal).
  def place_name
    if location
      location.display_name
    elsif User.current_location_format == :scientific
      Location.reverse_name(where)
    else
      where
    end
  end

  # Set +where+ or +location+, depending on whether a Location is defined with
  # the given +display_name+.  (Fills the other in with +nil+.)
  # Adjusts for the current user's location_format as well.
  def place_name=(place_name)
    where = if User.current_location_format == :scientific
              Location.reverse_name(place_name)
            else
              place_name
            end
    if (loc = Location.find_by_name(where))
      self.where = loc.name
      self.location = loc
    else
      self.where = where
      self.location = nil
    end
  end

  # Return title in plain text for debugging.
  def text_name
    title.t.html_to_ascii
  end

  # Alias for title.
  def format_name
    title
  end

  # Return formatted title with id appended to make in unique.
  def unique_format_name
    title = self.title
    if title.blank?
      :SPECIES_LIST.l + " ##{id || "?"}"
    else
      title + " (#{id || "?"})"
    end
  end

  # Return plain ASCII title with id appended to make unique.
  def unique_text_name
    unique_format_name.t.html_to_ascii
  end

  # Get list of Names, sorted by sort_name, for this list's Observation's.
  def names
    Name.where(id: observations.map(&:name_id).uniq).order("sort_name ASC")
  end

  # Tests to see if the species list includes an Observation with the given
  # Name (checks consensus only).  Primarily used by functional tests.
  def name_included(name)
    observations.map(&:name_id).include?(name.id)
  end

  # After defining a location, update any lists using old "where" name.
  # Original SQL:
  # UPDATE species_lists
  # SET `where` = #{new_name}, location_id = #{location.id}
  # WHERE `where` = #{old_name}
  def self.define_a_location(location, old_name)
    # Note: Need to use connection.quote_string here
    old_name = SpeciesList.connection.quote_string(old_name)
    new_name = SpeciesList.connection.quote_string(location.name)

    SpeciesList.where(where: old_name).update_all(
      where: new_name, location_id: location.id
    )
  end

  # Add observation to list (if not already) and set updated_at.  Saves it.
  def add_observation(obs)
    return if observations.include?(obs)

    observations.push(obs)
    update_attribute(:updated_at, Time.zone.now)
  end

  # Remove observation from list and set updated_at.  Saves it.
  def remove_observation(obs)
    return unless observations.include?(obs)

    observations.delete(obs)
    update_attribute(:updated_at, Time.zone.now)
  end

  ##############################################################################
  #
  #  :section: Construction
  #
  ##############################################################################

  # Upload file into internal "data" attribute.
  #
  #   spl = SpeciesList.new(args)
  #   spl.file = params[:file_upload]
  #   spl.process_file_data(sorter = NameSorter.new)
  #   names = sorter.xxx
  #
  def file=(file_field)
    if file_field.respond_to?(:read) &&
       file_field.respond_to?(:content_type)
      content_type = file_field.content_type.chomp
      case content_type
      when "text/plain",
           "application/text",
           "application/octet-stream"
        self.data = file_field.read
      else
        raise("Unrecognized content_type: #{content_type.inspect}")
      end
    else
      raise("Unrecognized file_field class: #{file_field.inspect}")
    end
  end

  # Process uploaded file.
  #
  #   spl = SpeciesList.new(args)
  #   spl.data = File.read('species_list.txt')
  #   spl.process_file_data(sorter = NameSorter.new)
  #   names = sorter.xxx
  #
  def process_file_data(sorter)
    return unless data

    if data[0] == 91 # '[' character
      process_name_list(sorter)
    else
      process_simple_list(sorter)
    end
  end

  # Process simple list: one Name per line.
  def process_simple_list(sorter)
    data.split(/\s*[\n\r]+\s*/).each do |name|
      sorter.add_name(name.strip_squeeze)
    end
  end

  # Process species lists that get generated by the Name species listing
  # program(??)  I think this was some external script Nathan wrote for Darvin.
  def process_name_list(sorter)
    entry_text = data.delete("[").split(/\s*\r\]\r\s*/)
    entry_text.each do |e|
      timestamp = nil
      what = nil
      e.split(/\s*\r\s*/).each do |key_value|
        kv = key_value.split(/\s*\|\s*/)
        if kv.length != 2
          raise(format("Bad key|value pair (%s) in %s", key_value, filename))
        end

        key, value = kv
        case key
        when "Date"
          # timestamp = Time.local(*(ParseDate.parsedate(value)))
          timestamp = Time.zone.parse(value)
        when "Name"
          what = value.strip.squeeze(" ")
        when "Time"
          # Ignore
        else
          raise(format("Unrecognized key|value pair: %s\n", key_value))
        end
      end
      sorter.add_name(what, timestamp) if what
    end
  end

  # Create and add a minimal Observation (with associated Naming and optional
  # Vote objects), and add it to the SpeciesList. Allowed parameters and their
  # default values are:
  #
  #   spl.construct_observation(
  #     name,                   #  **NO DEFAULT **
  #     :user                   => User.current,
  #     :projects               => spl.projects,
  #     :when                   => spl.when,
  #     :where                  => spl.where,
  #     :location               => spl.location,
  #     :vote                   => Vote.maximum_vote,
  #     :notes                  => '',
  #     :lat                    => nil,
  #     :long                   => nil,
  #     :alt                    => nil,
  #     :is_collection_location => true,
  #     :specimen               => false
  #   )
  #
  def construct_observation(name, args = {})
    raise("missing or invalid name: #{name.inspect}") unless name.is_a?(Name)

    args[:user] ||= User.current
    args[:when] ||= self.when
    args[:vote] ||= Vote.maximum_vote
    args[:notes] ||= ""
    args[:projects] ||= projects
    if !args[:where] && !args[:location]
      args[:where]    = location ? location.name : where
      args[:location] = location
    end
    args[:is_collection_location] = true if args[:is_collection_location].nil?
    args[:specimen] = false if args[:specimen].nil?

    obs = Observation.create(
      user: args[:user],
      when: args[:when],
      where: args[:where],
      location: args[:location],
      name: name,
      notes: args[:notes],
      lat: args[:lat],
      long: args[:long],
      alt: args[:alt],
      is_collection_location: args[:is_collection_location],
      specimen: args[:specimen]
    )
    args[:projects].each do |project|
      project.add_observation(obs)
    end

    naming = Naming.create(
      user: args[:user],
      name: name,
      observation: obs
    )

    if args[:vote] && (args[:vote].to_i != 0)
      obs.change_vote(naming, args[:vote], args[:user])
    end

    observations << obs
  end

  ##############################################################################
  #
  #  :section: Member notes
  #
  ##############################################################################

  # Array of notes for Observations wich are members of a SpeciesList.
  # Not currently persisted in the db, and is set up in the params hash as
  # params[member][notes], not params[species_list][member][notes]

  # id of view textarea for a member notes heading
  def self.notes_part_id(part)
    "#{notes_area_id_prefix}#{part.tr(" ", "_")}"
  end

  def notes_part_id(part)
    SpeciesList.notes_part_id(part)
  end

  # prefix for id of textarea
  def self.notes_area_id_prefix
    "member_notes_"
  end

  # name of view textarea for a member notes heading
  def self.notes_part_name(part)
    "member[notes][#{part.tr(" ", "_")}]"
  end

  def notes_part_name(part)
    SpeciesList.notes_part_name(part)
  end

  # Array of member note parts (Strings) to display in create & edit form
  def form_notes_parts(user)
    user.notes_template_parts << Observation.other_notes_part
  end

  ##############################################################################
  #
  #  :section: Projects
  #
  ##############################################################################

  def can_edit?(user = User.current)
    Project.can_edit?(self, user)
  end

  ##############################################################################
  #
  #  :section: Validation
  #
  ##############################################################################

  protected

  include Validations

  validate :check_requirements, :check_when

  def check_requirements
    # Clean off leading/trailing whitespace from +where+.
    self.where = where.strip_squeeze if where
    self.where = nil if where == ""

    if title.to_s.blank?
      errors.add(:title, :validate_species_list_title_missing.t)
    elsif title.size > 100
      errors.add(:title, :validate_species_list_title_too_long.t)
    end

    if place_name.to_s.blank? && !location
      errors.add(:place_name, :validate_species_list_where_missing.t)
    elsif where.to_s.size > 1024
      errors.add(:place_name, :validate_species_list_where_too_long.t)
    end

    return unless !user && !User.current

    errors.add(:user, :validate_species_list_user_missing.t)
  end

  def check_when
    self.when ||= Time.zone.now
    validate_when(self.when, errors)
  end
end
