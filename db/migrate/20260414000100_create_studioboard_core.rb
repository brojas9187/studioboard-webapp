class CreateStudioboardCore < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_salt, null: false
      t.string :password_digest, null: false

      t.timestamps
    end
    add_index :users, "lower(email)", unique: true, name: "index_users_on_lower_email"

    create_table :organizations do |t|
      t.string :name, null: false
      t.string :plan, null: false, default: "free"
      t.string :stripe_customer_id
      t.string :stripe_subscription_id

      t.timestamps
    end
    add_index :organizations, :stripe_customer_id
    add_index :organizations, :stripe_subscription_id

    create_table :memberships do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false, default: "member"

      t.timestamps
    end
    add_index :memberships, %i[organization_id user_id], unique: true

    create_table :projects do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :creator, null: false, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.text :description

      t.timestamps
    end

    create_table :tasks do |t|
      t.references :project, null: false, foreign_key: true
      t.references :creator, null: false, foreign_key: { to_table: :users }
      t.references :assignee, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description
      t.boolean :completed, null: false, default: false
      t.datetime :completed_at

      t.timestamps
    end
    add_index :tasks, %i[project_id completed]
  end
end
