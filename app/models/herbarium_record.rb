#
#  = HerbariumRecords Model
#
#  Represents a record of a physical collection at an herbarium.  Each time
#  a specimen is accessioned at an herbarium it will be given a label and a
#  unique identifier.  This info can be stored in this record.
#
#  Each HerbariumRecord belongs to an Herbarium, and can belong to one or
#  more Observation(s).  Note that either an observer or an Herbarium curator
#  can create one of these records.
#
#  See also CollectionNumber.
#
#  == Attributes
#
#  id::               Locally unique numerical id, starting at 1.
#  user_id::          Id of User who created this record at MO.
#  created_at::       Date/time this record was created at MO.
#  updated_at::       Date/time this record was last updated at MO.
#  herbarium_id::     Id of Herbarium containing this record.
#  initial_det::      Initial determination of the specimen.
#  accession_number:: Herbarium's unique identifier number.
#  notes::            Random notes about this record (optional).
#
#  == Class methods
#
#  None
#
#  == Instance methods
#
#  observations::     Observations associated with this record.
#  can_edit?::        Can a given user edit this record?
#  add_observation::  Add record to Observation, log it and save.
#  herbarium_label::  Initial determination + accession number.
#  format_name::      Same as herbarium_label.
#  accession_at_herbarium:: Format as "spec #nnnn @ Herbarium".
#
#  == Callbacks
#
#  notify curators::  Email curators when non-curator adds a record to an
#                     Herbarium.  Called after create.
#
class HerbariumRecord < AbstractModel
  belongs_to :herbarium
  belongs_to :user
  has_and_belongs_to_many :observations

  # Used to allow herbarium name to be entered as text in forms.
  attr_accessor :herbarium_name

  after_create :notify_curators

  def herbarium_label
    initial_det.blank? ? accession_number :
                         "#{initial_det}: #{accession_number}"
  end

  def format_name
    herbarium_label
  end

  def accession_at_herbarium
    "__#{accession_number}__ @ #{herbarium.format_name}"
  end

  # Can a given user edit this HerbariumRecord?
  def can_edit?(user = User.current)
    self.user == user || herbarium.is_curator?(user)
  end

  # Add this HerbariumRecord to an Observation, log the action, and save it.
  def add_observation(obs)
    return if observations.include?(obs)
    observations.push(obs)
    obs.specimen = true
    obs.log(:log_herbarium_record_added, name: herbarium_label, touch: true)
    obs.save
  end

  # Send email notifications when herbarium_record created by non-curator.
  def notify_curators
    sender = User.current
    recipients = herbarium.curators
    return if recipients.member?(sender)
    recipients.each do |recipient|
      email_klass = QueuedEmail::AddHerbariumRecordNotCurator
      email_klass.create_email(sender, recipient, self)
    end
  end
end
