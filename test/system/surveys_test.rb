require "application_system_test_case"

class SurveysTest < ApplicationSystemTestCase
  setup do
    @survey = surveys(:one)
  end

  test "visiting the index" do
    visit surveys_url
    assert_selector "h1", text: "Surveys"
  end

  test "should create survey" do
    visit surveys_url
    click_on "New survey"

    fill_in "Aggregated", with: @survey.aggregated
    fill_in "Convert url", with: @survey.convert_url
    fill_in "Definition", with: @survey.definition
    fill_in "Grades", with: @survey.grades
    fill_in "Group", with: @survey.group_id
    fill_in "Merged", with: @survey.merged
    fill_in "Name", with: @survey.name
    fill_in "Question attributes", with: @survey.question_attributes
    fill_in "Questions", with: @survey.questions
    fill_in "Student attributes", with: @survey.student_attributes
    fill_in "Subjects", with: @survey.subjects
    check "Updatable" if @survey.updatable
    click_on "Create Survey"

    assert_text "Survey was successfully created"
    click_on "Back"
  end

  test "should update Survey" do
    visit survey_url(@survey)
    click_on "Edit this survey", match: :first

    fill_in "Aggregated", with: @survey.aggregated
    fill_in "Convert url", with: @survey.convert_url
    fill_in "Definition", with: @survey.definition
    fill_in "Grades", with: @survey.grades
    fill_in "Group", with: @survey.group_id
    fill_in "Merged", with: @survey.merged
    fill_in "Name", with: @survey.name
    fill_in "Question attributes", with: @survey.question_attributes
    fill_in "Questions", with: @survey.questions
    fill_in "Student attributes", with: @survey.student_attributes
    fill_in "Subjects", with: @survey.subjects
    check "Updatable" if @survey.updatable
    click_on "Update Survey"

    assert_text "Survey was successfully updated"
    click_on "Back"
  end

  test "should destroy Survey" do
    visit survey_url(@survey)
    click_on "Destroy this survey", match: :first

    assert_text "Survey was successfully destroyed"
  end
end
