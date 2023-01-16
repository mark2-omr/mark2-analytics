require "test_helper"

class ResultsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @result = results(:one)
  end

  test "should get index" do
    get results_url
    assert_response :success
  end

  test "should get new" do
    get new_result_url
    assert_response :success
  end

  test "should create result" do
    assert_difference("Result.count") do
      post results_url, params: { result: { converted: @result.converted, grade: @result.grade, messages: @result.messages, parsed: @result.parsed, subject: @result.subject, survey_id: @result.survey_id, uploaded: @result.uploaded, user_id: @result.user_id, verified: @result.verified } }
    end

    assert_redirected_to result_url(Result.last)
  end

  test "should show result" do
    get result_url(@result)
    assert_response :success
  end

  test "should get edit" do
    get edit_result_url(@result)
    assert_response :success
  end

  test "should update result" do
    patch result_url(@result), params: { result: { converted: @result.converted, grade: @result.grade, messages: @result.messages, parsed: @result.parsed, subject: @result.subject, survey_id: @result.survey_id, uploaded: @result.uploaded, user_id: @result.user_id, verified: @result.verified } }
    assert_redirected_to result_url(@result)
  end

  test "should destroy result" do
    assert_difference("Result.count", -1) do
      delete result_url(@result)
    end

    assert_redirected_to results_url
  end
end
