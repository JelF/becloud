# frozen_string_literal: true

require 'becloud/config'
require 'becloud/sequel'
require 'becloud/db_utils'
require 'becloud/row_obfuscator'
require 'becloud/unique_index_resolving'

# TODO Source db might change while obfuscating

module Becloud::Obfuscation

  class << self

    def obfuscate(config_path)
      start_time     = Time.now
      config         = Becloud::Config.load_config(config_path)
      source_db_name = config.source_db_name

      # TODO Support all source db connection params (host, username, password, etc...)
      Becloud::Sequel.connect(source_db_name) do |source_db|
        target_db_name = config.target_db_name

        puts 'Resetting schema'
        Becloud::DBUtils.reset_target_schema(source_db_name, target_db_name)

        # TODO Support all target db connection params (host, username, password, etc...)
        Becloud::Sequel.connect(target_db_name) do |target_db|
          puts 'Removing foreign keys'
          Becloud::DBUtils.remove_foreign_keys(target_db)

          populate_target_db(source_db, target_db, config.rules(source_db))

          puts 'Applying foreign keys'
          Becloud::DBUtils.apply_foreign_keys(source_db, target_db)

          puts 'Resetting sequences'
          Becloud::DBUtils.reset_sequences(target_db)
        end
      end

      puts "Done (#{(Time.now - start_time).round}s)"
    end

    private

    # TODO Threads (parallel tables? parallel table content?)
    # TODO Copy tables which do not need obfuscation
    def populate_target_db(source_db, target_db, rules)
      source_db.tables.each do |table|
        puts "Processing #{table}"

        metadata       = source_db.schema(table).to_h
        table_rules    = rules[table]
        unique_indices = Becloud::UniqueIndexResolving.resolve_indices(source_db, table)
        obfuscator     = Becloud::RowObfuscator.new(metadata, unique_indices, table_rules)

        Becloud::Sequel.read_in_batches(source_db, table) do |batch|
          obfuscated_rows = batch.map { |row| obfuscator.obfuscate_row(row) }
          target_db[table].multi_insert(obfuscated_rows)
        end
      end
    end
  end
end
