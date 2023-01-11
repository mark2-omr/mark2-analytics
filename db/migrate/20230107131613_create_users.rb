class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.integer :group_id
      t.string :provider
      t.string :uid
      t.string :email
      t.string :name
      t.boolean :admin, default: false
      t.boolean :manager, default: false

      t.timestamps
    end

    add_index :users, %i[provider uid], unique: true
    add_index :users, :group_id
  end
end
