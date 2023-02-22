namespace :survey do
  task aggregate: :environment do
    Survey
      .where(submittable: true)
      .each do |survey|
        patterns, correct_ratios, categories, histograms =
          Hash.new,
          Hash.new,
          Hash.new,
          Hash.new

        survey.questions.each do |key, questions|
          grade, subject = key.split("-")

          # Aggregation for Total
          selected_results = Array.new
          Result
            .where(survey_id: survey.id, grade: grade, subject: subject)
            .each { |result| selected_results += result.converted }
          result =
            Result.new(
              survey_id: survey.id,
              grade: grade,
              subject: subject,
              converted: selected_results,
            )
          patterns["#{grade}-#{subject}-all"] = result.patterns
          correct_ratios["#{grade}-#{subject}-all"] = result.correct_ratios
          categories["#{grade}-#{subject}-all"] = result.categories
          histograms["#{grade}-#{subject}-all"] = result.histogram

          # Aggregation for Student Attibutes
          survey
            .student_attributes
            .each_with_index do |(student_attribute_label, student_attribute_values), i|
            next if student_attribute_label == I18n.t("views.class")

            student_attribute_values.each do |key, value|
              student_attributes = Array.new(survey.student_attributes.size, 0)
              student_attributes[i] = key

              patterns[
                "#{grade}-#{subject}-#{student_attribute_label}-#{key}"
              ] = result.patterns(student_attributes)
              correct_ratios[
                "#{grade}-#{subject}-#{student_attribute_label}-#{key}"
              ] = result.correct_ratios(student_attributes)
              categories[
                "#{grade}-#{subject}-#{student_attribute_label}-#{key}"
              ] = result.categories(student_attributes)
              histograms[
                "#{grade}-#{subject}-#{student_attribute_label}-#{key}"
              ] = result.histogram(student_attributes)
            end
          end
        end

        survey.aggregated = {
          patterns: patterns,
          correct_ratios: correct_ratios,
          categories: categories,
          histograms: histograms,
        }
        survey.save
      end
  end
end
