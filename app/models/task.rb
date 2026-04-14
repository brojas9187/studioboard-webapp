class Task < ApplicationRecord
  belongs_to :project
  belongs_to :creator, class_name: "User"
  belongs_to :assignee, class_name: "User"

  delegate :organization, to: :project

  validates :title, presence: true
  validate :creator_must_belong_to_organization
  validate :assignee_must_belong_to_organization

  scope :ordered, -> { order(completed: :asc, created_at: :desc) }

  def toggle_completion!
    new_state = !completed?
    update!(completed: new_state, completed_at: (new_state ? Time.current : nil))
  end

  def manageable_by?(membership)
    return false unless membership.present?

    membership.owner? || membership.admin? || assignee_id == membership.user_id
  end

  private

  def creator_must_belong_to_organization
    return if project.blank? || creator.blank?
    return if project.organization.users.exists?(creator.id)

    errors.add(:creator, :must_belong_to_organization)
  end

  def assignee_must_belong_to_organization
    return if project.blank? || assignee.blank?
    return if project.organization.users.exists?(assignee.id)

    errors.add(:assignee, :must_belong_to_organization)
  end
end
