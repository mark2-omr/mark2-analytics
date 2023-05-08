class CreateSurveys < ActiveRecord::Migration[7.0]
  def change
    create_table :surveys do |t|
      t.integer :group_id
      t.string :name
      t.binary :definition
      t.string :convert_url
      t.json :grades
      t.json :subjects
      t.json :questions
      t.json :question_attributes
      t.json :student_attributes
      t.boolean :submittable, default: true
      t.json :aggregated
      t.binary :merged
      t.date :held_on

      t.timestamps
    end

    add_index :surveys, :group_id
  end
end
