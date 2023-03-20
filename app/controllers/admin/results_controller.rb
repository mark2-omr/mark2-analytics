class Admin::ResultsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_result, only: %i[show edit update destroy download]
  before_action :set_survey_and_user, only: %i[ index new ]

  # GET /results or /results.json
  def index
    @results = Result.where(survey_id: @survey.id, user_id: @user.id).order('grade ASC, subject ASC')
  end

  # GET /results/1 or /results/1.json
  def show
  end

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
          subject: @result.subject
        },
        alert: @result.messages.join('<br />')
      )
      return
    end

    @result.file = params[:result][:file].read

    respond_to do |format|
      if @result.save
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
    @result.destroy

    respond_to do |format|
      format.html do
        redirect_to admin_result_url(survey_id: @result.survey.id,
          user_id: @result.user.id), notice: t('messages.result_destroyed')
      end
      format.json { head :no_content }
    end
  end

  def download
    send_data(@result.file, filename: "#{@result.id}.xlsx")
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_result
    @result = Result.find(params[:id])
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
