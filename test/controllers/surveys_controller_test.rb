require "test_helper"

class SurveysControllerTest < ActionDispatch::IntegrationTest
  setup do
    @survey = surveys(:one)
  end

  test "should get index" do
    get surveys_url
    assert_response :success
  end

  test "should get new" do
    get new_survey_url
    assert_response :success
  end

  test "should create survey" do
    assert_difference("Survey.count") do
      post surveys_url, params: { survey: { aggregated: @survey.aggregated, convert_url: @survey.convert_url, definition: @survey.definition, grades: @survey.grades, group_id: @survey.group_id, merged: @survey.merged, name: @survey.name, question_attributes: @survey.question_attributes, questions: @survey.questions, student_attributes: @survey.student_attributes, subjects: @survey.subjects, updatable: @survey.updatable } }
    end

    assert_redirected_to survey_url(Survey.last)
  end

  test "should show survey" do
    get survey_url(@survey)
    assert_response :success
  end

  test "should get edit" do
    get edit_survey_url(@survey)
    assert_response :success
  end

  test "should update survey" do
    patch survey_url(@survey), params: { survey: { aggregated: @survey.aggregated, convert_url: @survey.convert_url, definition: @survey.definition, grades: @survey.grades, group_id: @survey.group_id, merged: @survey.merged, name: @survey.name, question_attributes: @survey.question_attributes, questions: @survey.questions, student_attributes: @survey.student_attributes, subjects: @survey.subjects, updatable: @survey.updatable } }
    assert_redirected_to survey_url(@survey)
  end

  test "should destroy survey" do
    assert_difference("Survey.count", -1) do
      delete survey_url(@survey)
    end

    assert_redirected_to surveys_url
  end
end
