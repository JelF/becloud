# frozen_string_literal: true

require 'becloud/sequel'

module Becloud::UniqueIndexResolving

  class << self

    def resolve_indices(db, table)
      indices = db.indexes(table).values.select { |index| index[:unique] }
      indices = indices.map { |index| index[:columns] }

      primary_key = Becloud::Sequel.primary_key(db, table)
      indices.push(primary_key) if primary_key
      indices.flatten.uniq
    end
  end
end
