# frozen_string_literal: true

class Document < ActiveRecord::Base
  validates :name, presence: true

  has_and_belongs_to_many :tags
end
