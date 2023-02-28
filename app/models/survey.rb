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
            I18n.t("views.subject_#{key.split("-")[1]}") + " 正答率グループ"
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

  def cross_options(cross_param)
    cross_params = cross_param.split("-")

    if cross_params[2] == "0"
      return(
        {
          "1" => "正答率グループ1",
          "2" => "正答率グループ2",
          "3" => "正答率グループ3",
          "4" => "正答率グループ4",
        }
      )
    end

    options =
      self.questions["#{cross_params[0]}-#{cross_params[1]}"][
        cross_params[2].to_i
      ][
        "options"
      ]

    if options.size > 1
      return({ "1" => "正解", "2" => "不正解" })
    else
      return options[0]
    end
  end

  def cross(cross1, cross2)
    hash = Hash.new
    options1 = self.cross_options(cross1)
    options2 = self.cross_options(cross2)

    return { options1: options1, options2: options2 }
  end
end
