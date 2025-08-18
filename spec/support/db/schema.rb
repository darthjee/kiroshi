# frozen_string_literal: true

ActiveRecord::Schema.define do
  self.verbose = false

  create_table :documents, force: true do |t|
    t.string   :name
    t.string   :status
    t.boolean  :active
    t.integer  :priority
    t.string   :version
  end
end
