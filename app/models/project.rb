class Project < ApplicationRecord
  belongs_to :organization
  belongs_to :creator, class_name: "User"

  has_many :tasks, -> { order(completed: :asc, created_at: :desc) }, dependent: :destroy

  validates :name, presence: true
end
