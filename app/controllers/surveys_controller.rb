class SurveysController < ApplicationController
  before_action :authenticate_user!
  before_action :general_user_required
  before_action :set_survey, only: %i[show edit update destroy users download_definition]

  # GET /surveys or /surveys.json
  def index
    @surveys = Survey.where(group_id: current_user.group_id).order('held_on DESC')
  end

  # GET /surveys/1 or /surveys/1.json
  def show
    unless current_user.manager
      @results =
        Result.where(survey_id: @survey.id, user_id: current_user.id).order(
          'grade ASC, subject ASC'
        )
    end
  end

  def analyze
    @surveys = Survey.where(group_id: current_user.group_id).order('held_on DESC')
    if params[:survey_id]
      @survey = Survey.find(params[:survey_id])
    else
      @survey = @surveys.first
    end

    @student_attributes = Array.new
    @survey.student_attributes.each_with_index do |(key, values), i|
      options = Hash.new
      options["#{t("views.all")} (#{key})"] = 0

      options = options.update(values.invert)
      options = options.sort {|(k1, v1), (k2, v2)| v1.to_i <=> v2.to_i }.to_h
      @student_attributes.push(options)
    end

    @comparators = [[t('views.all'), [[t('views.all'), 'all']]]]
    @survey.student_attributes.each do |attribute_label, attribute_values|
      next if attribute_label == t('views.class')

      values = []
      attribute_values = attribute_values.sort{|a, b| a[0].to_i <=> b[0].to_i}.to_h
      attribute_values.each do |attribute_key, attribute_value|
        values.push([attribute_value, "#{attribute_label}-#{attribute_key}"])
      end
      @comparators.push([attribute_label, values])
    end

    if params[:commit]
      if params[:method] == 'cross'
        @cross = @survey.cross(params[:cross1], params[:cross2], params[:student_attributes], current_user)
      else
        @result = Result.where(user_id: current_user.id, survey_id: @survey.id, grade: params[:grade], subject: params[:subject]).first
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_survey
    @survey = Survey.find(params[:id])
    unless @survey.group_id == current_user.group_id
      redirect_to root_url
    end
  end

  # Only allow a list of trusted parameters through.
  def survey_params
    params.require(:survey).permit(
      :group_id,
      :name,
      :definition,
      :convert_url,
      :grades,
      :subjects,
      :questions,
      :question_attributes,
      :student_attributes,
      :submittable,
      :aggregated,
      :merged
    )
  end
end
