class Organization < ApplicationRecord
  PLAN_LIMITS = {
    "free" => { projects: 2, members: 3 },
    "pro" => { projects: nil, members: nil }
  }.freeze

  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :projects, dependent: :destroy

  validates :name, presence: true
  validates :plan, inclusion: { in: PLAN_LIMITS.keys }

  def free?
    plan == "free"
  end

  def pro?
    plan == "pro"
  end

  def project_limit
    PLAN_LIMITS.fetch(plan)[:projects]
  end

  def member_limit
    PLAN_LIMITS.fetch(plan)[:members]
  end

  def can_add_project?
    project_limit.nil? || projects.count < project_limit
  end

  def can_add_member?
    member_limit.nil? || memberships.count < member_limit
  end

  def projects_left
    return "Unlimited" if project_limit.nil?

    [project_limit - projects.count, 0].max
  end

  def members_left
    return "Unlimited" if member_limit.nil?

    [member_limit - memberships.count, 0].max
  end

  def upgrade_to_pro!(customer_id: nil, subscription_id: nil)
    update!(
      plan: "pro",
      stripe_customer_id: customer_id.presence || stripe_customer_id,
      stripe_subscription_id: subscription_id.presence || stripe_subscription_id
    )
  end
end
