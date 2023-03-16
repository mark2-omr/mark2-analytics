class Survey < ApplicationRecord
  belongs_to :group

  def load_definition(path)
    workbook = Roo::Excelx.new(path)
    sheet = workbook.sheet(0)

    # Numbers of Grades and Subjects
    grades, subjects = Array.new, Array.new
    (2..sheet.last_row).each do |i|
      grades.push(sheet.cell(i, 1).to_i) if sheet.cell(i, 1).to_i != 0
      subjects.push(sheet.cell(i, 2).to_i) if sheet.cell(i, 2).to_i != 0
    end
    self.grades = grades.uniq.sort
    self.subjects = subjects.uniq.sort

    # Numbers of Options
    options = Array.new
    (6..sheet.last_column).each do |i|
      options.push(sheet.cell(1, i).to_i) if sheet.cell(1, i).to_s =~ /\d+/
    end

    # Question Attributes
    question_attributes = Array.new
    ((5 + options.size)..sheet.last_column).each do |i|
      unless sheet.cell(1, i).to_s =~ /\d+/
        question_attributes.push(sheet.cell(1, i).to_s)
      end
    end
    self.question_attributes = question_attributes

    # Questions
    questions, hash = Hash.new, Hash.new
    (2..sheet.last_row).each do |i|
      grade_id = sheet.cell(i, 1).to_i
      subject_id = sheet.cell(i, 2).to_i
      number = sheet.cell(i, 3).to_i

      unless questions.key?(grade_id.to_s + "-" + subject_id.to_s)
        questions[grade_id.to_s + "-" + subject_id.to_s] = Array.new
      end

      if grade_id == sheet.cell(i - 1, 1).to_i and
           subject_id == sheet.cell(i - 1, 2).to_i and
           number == sheet.cell(i - 1, 3).to_i
        # In case the question consists of multiple questions
        hash["corrects"].push(sheet.cell(i, 5).to_i)
        options_hash = Hash.new
        options.each_with_index do |option, j|
          if sheet.cell(i, j + 6).to_s.size > 0
            options_hash[option] = sheet.cell(i, j + 6).to_s.gsub(/\.0\Z/, "")
          end
        end
        hash["options"].push(options_hash)
      else
        hash = Hash.new
        hash["label"] = sheet.cell(i, 4).to_s
        hash["corrects"] = [sheet.cell(i, 5).to_i]

        options_hash = Hash.new
        options.each_with_index do |option, j|
          if sheet.cell(i, j + 6).to_s.size > 0
            options_hash[option] = sheet.cell(i, j + 6).to_s.gsub(/\.0\Z/, "")
          end
        end
        hash["options"] = [options_hash]

        question_attributes_hash = Hash.new
        question_attributes.each_with_index do |question_attribute, j|
          if sheet.cell(i, 5 + options.size + j + 1).to_s.size > 0
            question_attributes_hash[question_attribute] = sheet.cell(
              i,
              5 + options.size + j + 1,
            ).to_s
          end
        end
        hash["question_attributes"] = question_attributes_hash
      end

      if grade_id != sheet.cell(i - 1, 1).to_i or
           subject_id != sheet.cell(i - 1, 2).to_i or
           number != sheet.cell(i - 1, 3).to_i
        questions[grade_id.to_s + "-" + subject_id.to_s].push(hash)
      end
    end
    self.questions = questions

    # Student Attributes
    sheet = workbook.sheet(1)
    keys = Array.new
    sheet.last_column.times do |i|
      keys.push(sheet.cell(1, i + 1)) if sheet.cell(1, i + 1).to_s.size > 0
    end

    student_attributes = Hash.new
    keys.each_with_index do |key, i|
      hash = Hash.new
      (2..sheet.last_row).each do |j|
        if sheet.cell(j, i + 1).to_s.size > 0
          hash[(j - 1).to_s] = sheet.cell(j, i + 1)
        end
      end
      student_attributes[key] = hash
    end
    self.student_attributes = student_attributes
  end

  def cross_questions(grade = 0)
    options = Array.new
    self.questions.each do |key, values|
      if key.split("-")[1] != "6"
        label =
          I18n.t("views.grade_#{key.split("-")[0]}") + " " +
            I18n.t("views.subject_#{key.split("-")[1]}") + " " +
            I18n.t("views.analysis.correct_rates_group")
        options.push([label, key + "-0"])
      end
      values.each_with_index do |value, i|
        label =
          I18n.t("views.grade_#{key.split("-")[0]}") + " " +
            I18n.t("views.subject_#{key.split("-")[1]}") + " " + value["label"]
        options.push([label, key + "-" + (i + 1).to_s])
      end
    end

    return options
  end

  def cross_options(grade, subject, question_number)
    if question_number == 0
      return(
        {
          "1" => "#{I18n.t("views.analysis.correct_rates_group")} 1",
          "2" => "#{I18n.t("views.analysis.correct_rates_group")} 2",
          "3" => "#{I18n.t("views.analysis.correct_rates_group")} 3",
          "4" => "#{I18n.t("views.analysis.correct_rates_group")} 4",
        }
      )
    end

    options = self.questions["#{grade}-#{subject}"][question_number]["options"]

    if options.size > 1
      return(
        {
          "1" => I18n.t("views.analysis.correct"),
          "2" => I18n.t("views.analysis.incorrect"),
        }
      )
    else
      return options[0]
    end
  end

  def cross_count(results, grade, subject, question_number)
    count = Hash.new

    if question_number == 0
      correct_counts = Array.new

      p "#{grade}-#{subject}"
      questions = self.questions["#{grade}-#{subject}"]
      results.each do |student|
        correct_count = 0
        student["values"].each_with_index do |answer, i|
          correct_count += 1 if answer == questions[i]["corrects"]
        end
        correct_counts.push(correct_count)
      end
      correct_counts.sort!
    end

    results.each do |student|
      key =
        "#{student["student_attributes"].values.join("-")}-#{student["number"]}"
      if question_number == 0
        # Correct rate group
        correct_count = 0
        questions = self.questions["#{grade}-#{subject}"]
        student["values"].each_with_index do |answer, i|
          correct_count += 1 if answer == questions[i]["corrects"]
        end

        if correct_count >= correct_counts[(correct_counts.size * 0.75).to_i]
          count[key] = 1
        elsif correct_count >= correct_counts[(correct_counts.size * 0.5).to_i]
          count[key] = 2
        elsif correct_count >= correct_counts[(correct_counts.size * 0.25).to_i]
          count[key] = 3
        else
          count[key] = 4
        end
      elsif self.questions["#{grade}-#{subject}"][question_number - 1][
            "corrects"
          ].size > 1
        # Consists of multiple questions
        if self.questions["#{grade}-#{subject}"][question_number - 1][
             "corrects"
           ] == student["values"][question_number - 1]
          count[key] = 1
        else
          count[key] = 2
        end
      else
        count[key] = student["values"][question_number - 1].first
      end
    end

    return count
  end

  def cross(cross1, cross2, student_attributes, current_user)
    grade1, subject1, question_number1 = cross1.split("-").map!(&:to_i)
    grade2, subject2, question_number2 = cross2.split("-").map!(&:to_i)

    options1 = self.cross_options(grade1, subject1, question_number1)
    options2 = self.cross_options(grade2, subject2, question_number2)

    result =
      Result.find_by(
        user_id: current_user.id,
        survey_id: self.id,
        grade: grade1,
        subject: subject1,
      )
    return nil unless result
    results1 = result.filter(student_attributes)
    result =
      Result.find_by(
        user_id: current_user.id,
        survey_id: self.id,
        grade: grade2,
        subject: subject2,
      )
    return nil unless result
    results2 = result.filter(student_attributes)

    count1 = self.cross_count(results1, grade1, subject1, question_number1)
    count2 = self.cross_count(results2, grade2, subject2, question_number2)

    results = Hash.new
    count1.each do |key, value|
      if count2.key?(key)
        cross_key = "#{count1[key]}-#{count2[key]}"
        if results.key?(cross_key)
          results[cross_key] += 1
        else
          results[cross_key] = 1
        end
      end
    end

    return { options1: options1, options2: options2, results: results }
  end

  def self.pattern_chart(options)
    params = { type: "pie", values: options.values, labels: options.keys }

    return params
  end

  def self.histogram_chart(values)
    outputs = []
    values.each_with_index do |value, i|
      outputs.push([i.to_s, value])
    end

    return outputs
  end
end
