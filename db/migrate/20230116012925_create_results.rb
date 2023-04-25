class CreateResults < ActiveRecord::Migration[7.0]
  def change
    create_table :results do |t|
      t.integer :survey_id
      t.integer :user_id
      t.integer :grade
      t.integer :subject
      t.binary :file
      t.json :parsed
      t.json :converted
      t.json :messages
      t.boolean :verified

      t.timestamps
    end

    add_index :results, %i[survey_id user_id]
  end
end
