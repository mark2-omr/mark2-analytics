json.extract! result, :id, :survey_id, :user_id, :grade, :subject, :uploaded, :parsed, :converted, :messages, :verified, :created_at, :updated_at
json.url result_url(result, format: :json)
