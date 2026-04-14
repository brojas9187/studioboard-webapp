class Membership < ApplicationRecord
  enum :role, {
    owner: "owner",
    admin: "admin",
    member: "member"
  }

  belongs_to :organization
  belongs_to :user

  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :organization_id }
  validate :organization_can_only_have_one_owner, if: :owner?

  scope :alphabetical, -> { joins(:user).order("users.name ASC, users.email ASC") }

  private

  def organization_can_only_have_one_owner
    return if organization.blank?
    return unless organization.memberships.where(role: "owner").where.not(id: id).exists?

    errors.add(:role, :owner_already_exists)
  end
end
