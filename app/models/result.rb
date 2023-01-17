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
end
