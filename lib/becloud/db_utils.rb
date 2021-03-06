# frozen_string_literal: true

require 'tempfile'
require 'becloud/sequel'

module Becloud::DBUtils

  class << self

    # TODO Support all args in system commands (host, username, password, etc...)
    def reset_target_schema(source_db_name, target_db_name)
      dump_path = Tempfile.new.path

      run("pg_dump -s #{source_db_name} > #{dump_path}")
      run("dropdb --if-exists #{target_db_name} > /dev/null")
      run("createdb #{target_db_name} > /dev/null")
      run("psql #{target_db_name} < #{dump_path} > /dev/null")
    end

    def foreign_keys(db)
      foreign_keys = {}

      each_foreign_key(db) do |table, foreign_key|
        foreign_keys[table] ||= []
        foreign_keys[table].push(*foreign_key[:columns])
        foreign_keys[foreign_key[:table]] ||= []
        foreign_keys[foreign_key[:table]].push(*foreign_key[:key])
      end

      foreign_keys.map { |table, keys| [table, keys.uniq] }.to_h
    end

    def remove_foreign_keys(db)
      each_foreign_key(db) do |table, foreign_key|
        db.alter_table(table) do
          drop_foreign_key(foreign_key[:columns], name: foreign_key[:name])
        end
      end
    end

    def apply_foreign_keys(reference_db, db)
      each_foreign_key(reference_db) do |table, foreign_key|
        db.alter_table(table) do
          add_foreign_key(foreign_key[:columns], foreign_key[:table], name: foreign_key[:name])
        end
      end
    end

    def reset_sequences(db)
      db.tables.each { |table| db.reset_primary_key_sequence(table) }
    end

    private

    def run(command)
      abort("Error while executing: #{command}") unless system(command)
    end

    def each_foreign_key(db)
      db.tables.each do |table|
        db.foreign_key_list(table).each do |foreign_key|
          yield(table, foreign_key)
        end
      end
    end
  end
end
