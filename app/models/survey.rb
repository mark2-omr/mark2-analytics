class Survey < ApplicationRecord
  belongs_to :group

  def load_definition(path)
    workbook = RubyXL::Parser.parse(path)
    worksheet = workbook[1]
  end
end
