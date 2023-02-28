class SurveysController < ApplicationController
  before_action :authenticate_user!
  before_action :set_survey,
                only: %i[show edit update destroy download_definition]

  # GET /surveys or /surveys.json
  def index
    @surveys = Survey.where(group_id: current_user.group_id)
  end

  # GET /surveys/1 or /surveys/1.json
  def show
    unless current_user.manager
      @results =
        Result.where(survey_id: @survey.id, user_id: current_user.id).order(
          "grade ASC, subject ASC",
        )
    end
  end

  # GET /surveys/new
  def new
    @survey = Survey.new
  end

  # GET /surveys/1/edit
  def edit
  end

  # POST /surveys or /surveys.json
  def create
    @survey = Survey.new(survey_params)
    @survey.group_id = current_user.group.id
    @survey.definition = params[:survey][:definition].read
    @survey.load_definition(params[:survey][:definition].tempfile.to_path.to_s)

    respond_to do |format|
      if @survey.save
        format.html do
          redirect_to survey_url(@survey), notice: t("messages.survey_created")
        end
        format.json { render :show, status: :created, location: @survey }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json do
          render json: @survey.errors, status: :unprocessable_entity
        end
      end
    end
  end

  # PATCH/PUT /surveys/1 or /surveys/1.json
  def update
    respond_to do |format|
      if @survey.update(survey_params)
        if params[:survey][:definition]
          @survey.definition = params[:survey][:definition].read
          @survey.load_definition(
            params[:survey][:definition].tempfile.to_path.to_s,
          )
          @survey.save
        end

        format.html do
          redirect_to survey_url(@survey), notice: t("messages.survey_updated")
        end
        format.json { render :show, status: :ok, location: @survey }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json do
          render json: @survey.errors, status: :unprocessable_entity
        end
      end
    end
  end

  # DELETE /surveys/1 or /surveys/1.json
  def destroy
    @survey.destroy

    respond_to do |format|
      format.html do
        redirect_to surveys_url, notice: t("messages.survey_destroyed")
      end
      format.json { head :no_content }
    end
  end

  def download_definition
    send_data(@survey.definition, filename: "#{@survey.id}.xlsx")
  end

  def analyze
    @surveys = Survey.where(group_id: current_user.group_id)
    if params[:survey_id]
      @survey = Survey.find(params[:survey_id])
    else
      @survey = @surveys.first
    end

    @student_attributes = Array.new
    @survey.student_attributes.each_with_index do |(key, values), i|
      options = Hash.new
      options["#{t("views.all")} (#{key})"] = 0
      @student_attributes.push(options.update(values.invert))
    end

    @comparators = [[t("views.all"), [[t("views.all"), "all"]]]]
    @survey.student_attributes.each do |attribute_label, attribute_values|
      next if attribute_label == t("views.class")
      values = Array.new
      attribute_values.each do |attribute_key, attribute_value|
        values.push([attribute_value, "#{attribute_label}-#{attribute_key}"])
      end
      @comparators.push([attribute_label, values])
    end

    if params[:commit]
      if params[:method] == "cross"
        @cross = @survey.cross(params[:cross1], params[:cross2])
      else
        @result =
          Result.where(
            user_id: current_user.id,
            survey_id: @survey.id,
            grade: params[:grade],
            subject: params[:subject],
          ).first
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_survey
    @survey = Survey.find(params[:id])
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
      :merged,
    )
  end
end
