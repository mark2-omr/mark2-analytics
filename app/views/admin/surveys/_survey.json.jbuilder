json.extract! survey, :id, :group_id, :name, :definition, :convert_url, :grades, :subjects, :questions, :question_attributes, :student_attributes, :updatable, :aggregated, :merged, :created_at, :updated_at
json.url survey_url(survey, format: :json)
