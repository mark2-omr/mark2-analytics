class Result < ApplicationRecord
  belongs_to :survey
  belongs_to :user

  def load(workbook)
    sheet = workbook.sheet(0)
    self.parsed = sheet.to_matrix.to_json

    param = "grade=#{self.grade}&subject=#{self.subject}&parsed=#{self.parsed}"
    uri = URI.parse(self.survey.convert_url)
    http = Net::HTTP.new(uri.host, uri.port)
    if uri.scheme == "https"
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    response = JSON.parse(http.post(uri.path, param).body)

    students = Array.new
    response["converted"].each do |student|
      values = Array.new
      i = 0
      self.survey.questions["#{self.grade}-#{self.subject}"].each do |question|
        value = Array.new
        question["options"].size.times do |j|
          value.push(student["values"][i])
          i += 1
        end
        values.push(value)
      end
      student["values"] = values
      students.push(student)
    end

    # Check for duplicates
    student_keys = Array.new
    students.each do |student|
      student_keys.push(
        "#{student["student_attributes"].values.join("-")}-#{student["number"]}",
      )
    end
    if students.size == student_keys.uniq.size
      self.converted = students
      self.messages = [
        "#{students.size}#{I18n.t("messages.n_data_were_registered")}",
      ]
      self.verified = true
    else
      errors = Array.new
      students.each do |student|
        if student_keys.count(
             "#{student["student_attributes"].values.join("-")}-#{student["number"]}",
           ) > 1
          errors.push(
            "#{student["student_attributes"].values.join("-")}-#{student["number"]}",
          )
        end
      end
      errors.uniq!
      errors.map! do |error|
        buffer = I18n.t("messages.duplicate_student_information")
        self.survey.student_attributes.keys.each_with_index do |key, i|
          buffer +=
            "#{students.first["student_attributes"].keys[i]}: #{error.split("-")[i]}, "
        end
        buffer += "#{I18n.t("messages.number")}: #{error.split("-").last}"
      end

      self.converted = []
      self.messages = errors
      self.verified = false
    end
  end

  def filter(student_attributes)
    selected_results = self.converted
    self.survey.student_attributes.each_with_index do |(key, value), i|
      unless student_attributes[i].to_i == 0
        selected_results.select! do |a|
          a["student_attributes"][key] == student_attributes[i].to_i
        end
      end
    end

    return selected_results
  end

  def patterns(student_attributes = [])
    questions = self.survey.questions["#{self.grade}-#{self.subject}"]
    selected_results = self.filter(student_attributes)

    outputs = Array.new
    questions.each_with_index do |question, i|
      hash = { label: question["label"], options: Hash.new }

      if question["options"].size == 1
        question["options"].first["50"] = "無回答"
        question["options"].first.each do |key, value|
          count = 0
          selected_results.each do |selected_result|
            count += 1 if selected_result["values"][i].first == key.to_i
          end

          # （試験データ登録時のエクセル浮動小数点対応）
          value = value.to_i if value.include?(".0")
          hash[:options][value] = count
        end
      else
        selected_results.each do |selected_result|
          next if selected_result["values"][i].include?(99)

          key = String.new
          selected_result["values"][i].each_with_index do |value, j|
            key += "-" unless j == 0
            key += value.to_s
          end

          if hash[:options].key?(key)
            hash[:options][key] += 1
          else
            hash[:options][key] = 1
          end
        end
      end

      outputs.push(hash)
    end

    return outputs
  end

  def correct_rates(student_attributes = [])
    questions = self.survey.questions["#{self.grade}-#{self.subject}"]
    selected_results = self.filter(student_attributes)

    outputs = Array.new
    questions.each_with_index do |question, i|
      correct_count, total_count = 0.0, 0.0
      selected_results.each do |selected_result|
        if selected_result["values"][i] == question["corrects"]
          correct_count += 1.0
          total_count += 1.0
        elsif selected_result["values"][i].nil?
        elsif selected_result["values"][i].include?(99)
        else
          total_count += 1.0
        end
      end

      outputs.push(
        {
          question: question["label"],
          value: correct_count / total_count * 100,
        },
      )
    end

    return outputs
  end

  def categories(student_attributes = [])
    questions = self.survey.questions["#{self.grade}-#{self.subject}"]
    selected_results = self.filter(student_attributes)

    outputs = Array.new
    question_attributes = self.survey.question_attributes
    question_attributes.each do |question_attribute|
      outputs.push(title: question_attribute, values: Hash.new)
    end

    question_attributes.each_with_index do |question_attribute, i|
      questions.each_with_index do |question, j|
        label = question["question_attributes"][question_attribute]
        outputs[i][:values][label] = 0.0 unless outputs[i][:values].key?(label)
      end

      outputs[i][:values].each do |key, value|
        correct_count, total_count = 0.0, 0.0
        questions.each_with_index do |question, j|
          next unless question["question_attributes"][question_attribute] == key
          selected_results.each do |selected_result|
            if selected_result["values"][j] == question["corrects"]
              correct_count += 1.0
              total_count += 1.0
            elsif selected_result["values"][i].nil?
            elsif selected_result["values"][j].include?(99)
            else
              total_count += 1.0
            end
          end
        end

        outputs[i][:values][key] = correct_count / total_count * 100
      end
    end

    return outputs
  end

  def histogram(student_attributes = [])
    questions = self.survey.questions["#{self.grade}-#{self.subject}"]
    selected_results = self.filter(student_attributes)

    outputs = Array.new(questions.size + 1, 0)
    selected_results.each do |selected_result|
      correct_count = 0
      questions.each_with_index do |question, i|
        if selected_result["values"][i] == question["corrects"]
          correct_count += 1
        end
      end
      outputs[correct_count] += 1
    end

    return outputs
  end
end
