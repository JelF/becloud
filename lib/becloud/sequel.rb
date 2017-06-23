# frozen_string_literal: true

require 'sequel'

module Becloud::Sequel

  BATCH_SIZE = 1_000

  def self.connect(db_name)
    Sequel.connect(adapter: :postgresql, database: db_name) { |db| yield db }
  end

  # TODO Support composite primary keys
  def self.read_in_batches(db, table)
    primary_key = db.primary_key(table)
    return yield db[table].all unless primary_key

    offset = 0
    loop do
      batch = db[table].order(primary_key.to_sym).limit(BATCH_SIZE).offset(offset).all
      return if batch.empty?

      yield batch
      offset += BATCH_SIZE
    end
  end
end
