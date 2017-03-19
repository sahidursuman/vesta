# frozen_string_literal: true
#
# Service object to create memberships.
class MembershipCreator < Creator
  # Class method to permit calling :create! on the class without instantiating
  # the service object directly
  #
  # @param [#to_h] params The params for the membership
  def self.create!(params)
    new(params).create!
  end

  # Initialize a MembershipCreator
  #
  # @param [#to_h] params The params for the membership
  def initialize(params)
    super(klass: Membership, name_method: nil, params: params)
  end

  private

  def success
    { object: [obj.group.draw, obj.group], membership: obj,
      msg: { success: "Membership in #{obj.group.name} created for "\
        "#{obj.user.name}." } }
  end

  def error
    errors = obj.errors.full_messages
    {
      object: nil, membership: obj,
      msg: { error: "Please review the errors below:\n#{errors.join("\n")}" },
      errors: errors,
      params: params
    }
  end
end
