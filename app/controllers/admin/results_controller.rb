class Admin::ResultsController < ApplicationController
  before_action :authenticate_user!
  before_action :manager_required
  before_action :set_result, only: %i[destroy download]
  before_action :set_survey_and_user, only: %i[index new]

  # GET /results or /results.json
  def index
    @results = Result.where(survey_id: @survey.id, user_id: @user.id).order('grade ASC, subject ASC')
  end

  # GET /results/new
  def new
    @result = Result.new(user_id: params[:user_id], survey_id: params[:survey_id])
  end

  # POST /results or /results.json
  def create
    @result = Result.new(result_params)

    # Check grade and subject combination
    if @result.survey.questions.key?("#{@result.grade}-#{@result.subject}")
      Result.where(
        user_id: @result.user.id,
        survey_id: @result.survey_id,
        grade: @result.grade,
        subject: @result.subject,
      ).destroy_all
    else
      redirect_to(new_admin_result_url(user_id: @result.user.id,
                                       survey_id: @result.survey.id,
                                       grade: @result.grade,
                                       subject: @result.subject),
                  alert: t('messages.check_grade_and_subject'))
      return
    end

    begin
      workbook = Roo::Excelx.new(params[:result][:file].tempfile.to_path.to_s)
      @result.load(workbook)
      @result.file = params[:result][:file].read
    rescue StandardError
      redirect_to(new_admin_result_url(user_id: @result.user.id,
                                       survey_id: @result.survey.id,
                                       grade: @result.grade,
                                       subject: @result.subject),
                  alert: t('messages.data_convert_error'))
      return
    end

    unless @result.verified
      redirect_to(new_admin_result_url(user_id: @result.user.id,
                                       survey_id: @result.survey.id,
                                       grade: @result.grade,
                                       subject: @result.subject),
                  alert: @result.messages.join('<br />'))
      return
    end

    respond_to do |format|
      if @result.save
        log_audit("Create result##{@result.id}")
        format.html do
          redirect_to admin_results_url(survey_id: @result.survey.id,
            user_id: @result.user.id), notice: t('messages.result_created')
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
        redirect_to admin_results_url(survey_id: @result.survey.id,
          user_id: @result.user.id), notice: t('messages.result_destroyed')
      end
      format.json { head :no_content }
    end
  end

  def download
    log_audit("Download result##{@result.id}")
    send_data(@result.file, filename: "Mark2_File_#{@result.survey_id}_#{@result.user_id}_#{@result.grade}_#{@result.subject}.xlsx")
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_result
    @result = Result.find(params[:id])
    if @result.survey.group_id != current_user.group_id
      redirect_to root_url
    end
  end

  def set_survey_and_user
    @survey = Survey.find(params[:survey_id])
    @user = User.find(params[:user_id])
    if @survey.group_id != current_user.group_id or @user.group_id != current_user.group_id
      redirect_to root_url
    end
  end

  # Only allow a list of trusted parameters through.
  def result_params
    params.require(:result).permit(
      :survey_id,
      :user_id,
      :grade,
      :subject,
      :file,
      :parsed,
      :converted,
      :messages,
      :verified
    )
  end
end
