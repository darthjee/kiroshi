# frozen_string_literal: true

ActiveRecord::Schema.define do
  self.verbose = false

  create_table :documents, force: true do |t|
    t.string   :name
    t.string   :full_name
    t.string   :status
    t.boolean  :active
    t.integer  :priority
    t.string   :version
  end

  create_table :tags, force: true do |t|
    t.string :name, null: false
    t.index :name, unique: true
  end

  create_table :documents_tags, force: true do |t|
    t.references :document, null: false, foreign_key: true
    t.references :tag, null: false, foreign_key: true
    t.index %i[document_id tag_id], unique: true
  end
end
