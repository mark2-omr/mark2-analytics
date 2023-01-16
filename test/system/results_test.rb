require "application_system_test_case"

class ResultsTest < ApplicationSystemTestCase
  setup do
    @result = results(:one)
  end

  test "visiting the index" do
    visit results_url
    assert_selector "h1", text: "Results"
  end

  test "should create result" do
    visit results_url
    click_on "New result"

    fill_in "Converted", with: @result.converted
    fill_in "Grade", with: @result.grade
    fill_in "Messages", with: @result.messages
    fill_in "Parsed", with: @result.parsed
    fill_in "Subject", with: @result.subject
    fill_in "Survey", with: @result.survey_id
    fill_in "Uploaded", with: @result.uploaded
    fill_in "User", with: @result.user_id
    check "Verified" if @result.verified
    click_on "Create Result"

    assert_text "Result was successfully created"
    click_on "Back"
  end

  test "should update Result" do
    visit result_url(@result)
    click_on "Edit this result", match: :first

    fill_in "Converted", with: @result.converted
    fill_in "Grade", with: @result.grade
    fill_in "Messages", with: @result.messages
    fill_in "Parsed", with: @result.parsed
    fill_in "Subject", with: @result.subject
    fill_in "Survey", with: @result.survey_id
    fill_in "Uploaded", with: @result.uploaded
    fill_in "User", with: @result.user_id
    check "Verified" if @result.verified
    click_on "Update Result"

    assert_text "Result was successfully updated"
    click_on "Back"
  end

  test "should destroy Result" do
    visit result_url(@result)
    click_on "Destroy this result", match: :first

    assert_text "Result was successfully destroyed"
  end
end
