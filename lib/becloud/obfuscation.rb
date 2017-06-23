# frozen_string_literal: true

require 'becloud/config'
require 'becloud/sequel'
require 'becloud/target_utils'

# TODO Source db might change while obfuscating
# TODO Rewind sequences after obfuscation
# TODO Unique constraints

module Becloud::Obfuscation

  class << self

    def obfuscate(config_path)
      config         = Becloud::Config.load_config(config_path)
      source_db_name = config.source_db_name

      # TODO Support all source db connection params (host, username, password, etc...)
      Becloud::Sequel.connect(source_db_name) do |source_db|

        target_db_name = config.target_db_name
        puts 'Resetting target db schema'
        Becloud::TargetUtils.reset_target_schema(source_db_name, target_db_name)

        Becloud::Sequel.connect(target_db_name) do |target_db|
          puts 'Removing foreign keys'
          Becloud::TargetUtils.remove_foreign_keys(target_db)

          populate_target_db(source_db, target_db)

          puts 'Applying foreign keys'
          Becloud::TargetUtils.apply_foreign_keys(source_db, target_db)
        end
      end
    end

    private

    # TODO Obfuscate
    # TODO Memory usage
    # TODO Threads
    # TODO Ensure foreign keys are not obfuscated (both sides)
    def populate_target_db(source_db, target_db)
      source_db.tables.each do |table|
        puts "Processing #{table}"
        source_db[table].each do |row|
          target_db[table].insert(row)
        end
      end
    end
  end
end
