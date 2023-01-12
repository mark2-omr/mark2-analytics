class Group < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :surveys, dependent: :destroy
end
