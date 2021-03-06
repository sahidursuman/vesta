# frozen_string_literal: true

# Form object for room assignment. Ensures that all students in a group
# are assigned rooms, that all rooms belong to the group's suite, and that no
# room is assigned more students than beds.

# rubocop:disable ClassLength
class RoomAssignmentForm
  include ActiveModel::Model

  attr_reader :group

  validate :all_members_have_rooms
  validate :all_rooms_exist
  validate :no_overassigned_rooms

  # Initialize a new RoomAssignmentForm
  #
  # @param group [Group] the group in question
  def initialize(group:)
    @group = group
    @members = group.members
    @rooms = group.suite.rooms
  end

  # Prepare the RoomAssignmentForm for confirmation / execution, handles params
  # processing and validations
  #
  # @param p [#to_h] the parameters from the controller
  # @return [Hash] the results hash, empty if valid
  def prepare(p)
    process_params(p)
    @prep ||= valid? ? {} : error(self)
  end

  # Execute / save the room assignment
  #
  # @param p [#to_h] the parameters from the controller
  # @return [Hash{Symbol=>Group,Array,Hash}] the results hash
  def assign(p)
    return prepare(p) unless prepare(p).empty?
    create_room_assignment
    success
  rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
    error(e)
  end

  # Update existing room assignments
  #
  # @param p [#to_h] the parameters from the controller
  # @return [Hash{Symbol=>Group,Array,Hash}] the results hash
  def update(p)
    return prepare(p) unless prepare(p).empty?
    update_room_assignment
    success
  rescue ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
    error(e)
  end

  # Returns the valid form field ids for a given group
  #
  # @return [Array<Symbol>] the list of form fields
  def valid_field_ids
    return [] unless members
    @valid_field_ids ||= members.map { |m| param_for(m) }
  end

  # Return the display hash for the confirmation view, sets the rooms as keys
  # with an array of the assigned students as the values
  #
  # @return [Hash{Room=>Array<User>}] the assignment hash
  def assignment_hash
    members_per_room.transform_keys { |r_id| room(r_id) }
                    .transform_values { |ms| ms.map { |m_id| member(m_id) } }
  end

  # Generate assignment param hash and call prepare based on existing
  # assignments
  #
  # @return [RoomAssignment] returns self
  def build_from_group!
    params_hash = members.each_with_object({}) do |m, hash|
      hash[param_for(m).to_s] = m.room.id.to_s
      hash
    end
    prepare(params_hash)
    self
  end

  private

  attr_reader :members, :rooms, :params

  def process_params(p)
    assign_current_attrs(p)
    @params = p.to_h.reject { |_k, v| v.empty? }
               .transform_keys { |k| member_id_from_field(k) }
               .transform_values(&:to_i)
  end

  def assign_current_attrs(p)
    p.each { |k, v| instance_variable_set("@#{k}".to_sym, v) }
  end

  def all_members_have_rooms
    return if (members.map(&:id) - params.keys).empty?
    errors.add(:base, 'All members must have a room assigned')
  end

  def all_rooms_exist
    return true if (params.values.uniq - rooms.map(&:id)).empty?
    errors.add(:base, 'All rooms must exist')
    false
  end

  def no_overassigned_rooms
    return unless all_rooms_exist
    return unless members_per_room.any? do |r_id, ms|
      room(r_id).beds < ms.count
    end
    errors.add(:base, 'All rooms must have no more members than beds')
  end

  def members_per_room
    params.each_with_object({}) do |(k, v), room_hash|
      room_hash[v] ? room_hash[v] << k : room_hash[v] = [k]
      room_hash
    end
  end

  def room(id)
    rooms.find { |r| r.id == id }
  end

  def member(id)
    members.find { |m| m.id == id }
  end

  def success
    obj = group.draw ? [group.draw, group] : group
    { redirect_object: obj, msg: { notice: 'Successfully assigned rooms' } }
  end

  def error(e)
    msg = ErrorHandler.format(error_object: e)
    { redirect_object: nil, msg: { error: msg } }
  end

  # creates dynamic attr_readers for user fields
  def method_missing(method_name, *args, &block)
    super unless valid_field_ids.include? method_name
    instance_variable_get("@#{method_name}")
  end

  def param_for(member)
    "room_id_for_#{member.id}".to_sym
  end

  def member_id_from_field(field)
    /room_id_for_(\d+)$/.match(field)[1].to_i
  end

  def respond_to_missing?(method_name, include_all = false)
    valid_field_ids.include?(method_name) || super
  end

  def create_room_assignment
    ActiveRecord::Base.transaction do
      params.each do |student_id, room_id|
        RoomAssignment.create!(user_id: student_id, room_id: room_id)
      end
    end
  end

  def update_room_assignment
    ActiveRecord::Base.transaction do
      params.each do |student_id, room_id|
        r_a = RoomAssignment.find_by(user_id: student_id)
        r_a.update!(room_id: room_id)
      end
    end
  end
end
