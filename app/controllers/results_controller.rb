class ResultsController < ApplicationController
  before_action :authenticate_user!
  before_action :general_user_required
  before_action :set_result, only: %i[show destroy download]
  before_action :set_survey, only: %i[new create destroy download]

  # GET /results/new
  def new
    @survey = Survey.find(params[:survey_id])
    @result = Result.new(survey_id: params[:survey_id])
  end

  # POST /results or /results.json
  def create
    @result = Result.new(result_params)
    @result.user_id = current_user.id

    # Check grade and subject combination
    if @result.survey.questions.key?("#{@result.grade}-#{@result.subject}")
      Result.where(
        user_id: current_user.id,
        survey_id: @result.survey_id,
        grade: @result.grade,
        subject: @result.subject,
      ).destroy_all
    else
      redirect_to(
        {
          action: 'new',
          survey_id: @result.survey.id,
          grade: @result.grade,
          subject: @result.subject,
        },
        alert: t('messages.check_grade_and_subject'),
      )
      return
    end

    begin
      workbook = Roo::Excelx.new(params[:result][:file].tempfile.to_path.to_s)
      @result.load(workbook)
      @result.file = params[:result][:file].read
    rescue StandardError
      redirect_to(
        {
          action: 'new',
          survey_id: @result.survey.id,
          grade: @result.grade,
          subject: @result.subject,
        },
        alert: t('messages.data_convert_error'),
      )
      return
    end

    unless @result.verified
      redirect_to(
        {
          action: 'new',
          survey_id: @result.survey.id,
          grade: @result.grade,
          subject: @result.subject,
        },
        alert: @result.messages.join('<br />'),
      )
      return
    end

    respond_to do |format|
      if @result.save
        log_audit("Create result##{@result.id}")
        format.html do
          redirect_to @result.survey, notice: t('messages.result_created')
        end
        format.json { render :show, status: :created, location: @result }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json do
          render json: @result.errors, status: :unprocessable_entity
        end
      end
    end
  end

  # DELETE /results/1 or /results/1.json
  def destroy
    log_audit("Destroy result##{@result.id}")
    @result.destroy

    respond_to do |format|
      format.html do
        redirect_to @result.survey, notice: t("messages.result_destroyed")
      end
      format.json { head :no_content }
    end
  end

  def download
    log_audit("Download result##{@result.id}")
    send_data(@result.file, filename: "Mark2_File_#{@result.survey_id}_#{@result.grade}_#{@result.subject}.xlsx")
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_result
    @result = Result.find(params[:id])
    unless @result.user_id == current_user.id
      redirect_to root_url
    end
  end

  def set_survey
    if params[:action] == 'new'
      @survey = Survey.find(params[:survey_id])
    elsif params[:action] == 'create'
      @survey = Survey.find(result_params[:survey_id])
    elsif params[:action] == 'destroy' or params[:action] == 'download'
      @survey = Survey.find(@result.survey_id)
    end

    unless @survey.group_id == current_user.group_id
      redirect_to root_url
    end

    if params[:action] == 'new' or params[:action] == 'create' or
         params[:action] == 'destroy'
      unless @survey.submittable
        redirect_to @survey
      end
    end
  end

  def general_user_required
    if current_user.manager
      redirect_to root_url
    end
  end

  # Only allow a list of trusted parameters through.
  def result_params
    params.require(:result).permit(:survey_id, :user_id, :grade, :subject,
      :file, :parsed, :converted, :messages, :verified)
  end
end
