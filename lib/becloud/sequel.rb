# frozen_string_literal: true

require 'sequel'

module Becloud::Sequel

  # TODO Optimal value?
  BATCH_SIZE = 10_000

  class << self

    def connect(db_name)
      Sequel.connect(adapter: :postgresql, database: db_name) { |db| yield db }
    end

    def read_in_batches(db, table)
      primary_key = primary_key(db, table)
      return yield db[table].all unless primary_key

      offset = 0
      loop do
        batch = db[table].order(primary_key).limit(BATCH_SIZE).offset(offset).all
        return if batch.empty?

        yield batch
        offset += BATCH_SIZE
      end
    end

    # Sequel does not support returning composite primary keys
    def primary_key(db, table)
      result = db.fetch <<-SQL.strip
        SELECT a.attname, format_type(a.atttypid, a.atttypmod) AS data_type
        FROM pg_index i
        JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey)
        WHERE i.indrelid = '#{table}'::regclass AND i.indisprimary;
      SQL

      primary_key = result.map { |row| row[:attname].to_sym }
      primary_key if primary_key.any?
    end
  end
end
