class Admin::SurveysController < ApplicationController
  before_action :authenticate_user!
  before_action :manager_required
  before_action :set_survey, only: %i[show edit update destroy users download_definition download_merged_results aggregate_and_merge_results]

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
        log_audit("Create survey##{@survey.id}")
        format.html do
          redirect_to admin_survey_url(@survey), notice: t('messages.survey_created')
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
        log_audit("Update survey##{@survey.id}")
        if params[:survey][:definition]
          @survey.definition = params[:survey][:definition].read
          @survey.load_definition(
            params[:survey][:definition].tempfile.to_path.to_s,
          )
          @survey.save
        end

        format.html do
          redirect_to admin_survey_url(@survey), notice: t('messages.survey_updated')
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
    log_audit("Destroy survey##{@survey.id}")
    @survey.destroy

    respond_to do |format|
      format.html do
        redirect_to admin_surveys_url, notice: t('messages.survey_destroyed')
      end
      format.json { head :no_content }
    end
  end

  def users
    @users = User.where(group_id: @survey.group_id, manager: false)
  end

  def download_definition
    send_data(@survey.definition, filename: "Mark2_Definition_#{@survey.id}.xlsx")
  end

  def download_merged_results
    send_data(@survey.merged, filename: "Mark2_Results_#{@survey.id}.xlsx")
  end

  def aggregate_and_merge_results
    @survey.aggregate_results
    @survey.merge_results

    redirect_to admin_survey_url(@survey), notice: t('messages.survey_results_aggregated')
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_survey
    @survey = Survey.find(params[:id])
    if @survey.group_id != current_user.group_id
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
      :merged,
      :held_on
    )
  end
end
