# frozen_string_literal: true

# Things to check:
# * Poly or not
# * With and without condition
# * testable_has_one and testable_has_one
# * different :source
# * default_scopes

require_relative "base_test_model"

# Classes are names S0, S1, S2... for "Step"
# Relations are names m1, o2, b3 for "Many", "One", "Belong" and the id of the next step
# A class always point further down to the next steps

class S0 < BaseTestRecord
  testable_has_many :m1, class_name: "S1"
  testable_has_one :o1, -> { order("s1s.id DESC") }, class_name: "S1"
  belongs_to :b1, class_name: "S1", foreign_key: "s1_id"

  testable_has_many :m2m1, through: :m1, source: :m2, class_name: "S2"
  testable_has_one :o2o1, -> { order("s2s.id DESC") }, through: :o1, source: :o2, class_name: "S2"

  # 2 different ways of doing 3 steps:
  # one through after the other
  testable_has_many :m3m2m1, through: :m2m1, source: :m3, class_name: "S3"
  testable_has_one :o3o2o1, -> { order("s3s.id DESC") }, through: :o2o1, source: :o3, class_name: "S3"

  # one through with a source that uses another through
  testable_has_many :m3m1_m3m2, through: :m1, source: :m3m2, class_name: "S3"
  testable_has_one :o3o1_o3o2, -> { order("s3s.id DESC") }, through: :o1, source: :o3o2, class_name: "S3"
end

class S1 < BaseTestRecord
  testable_has_many :m2, class_name: "S2"
  testable_has_one :o2, -> { order("s2s.id DESC") }, class_name: "S2"
  belongs_to :b2, class_name: "S2"

  testable_has_many :m3m2, through: :m2, source: :m3, class_name: "S3"
  testable_has_one :o3o2, -> { order("s3s.id DESC") }, through: :o2, source: :o3, class_name: "S3"
end

class S2 < BaseTestRecord
  testable_has_many :m3, class_name: "S3"
  testable_has_one :o3, class_name: "S3"
  belongs_to :b3, class_name: "S3"
end

class S3 < BaseTestRecord
end


class SchemaS0 < ActiveRecord::Base
  self.table_name = "foo_schema.schema_s0s"
  belongs_to :b1, class_name: "SchemaS1", foreign_key: "schema_s1_id"
  has_many :m1, class_name: "SchemaS1", foreign_key: "schema_s0_id"
  has_one :o1, class_name: "SchemaS1", foreign_key: "schema_s0_id"
end

class SchemaS1 < ActiveRecord::Base
  self.table_name = "bar_schema.schema_s1s"
end
