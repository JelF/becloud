# frozen_string_literal: true

require 'becloud/db_utils'

# TODO Error on unknown code in config

module Becloud::Config

  class << self

    attr_reader :source_db_name
    attr_reader :target_db_name

    def load_config(path)
      abort('Obfuscation config path not specified') if !path || path.empty?
      config = File.read(File.expand_path(path, Dir.pwd))
      eval(config)
      self
    end

    # TODO Support rules in config
    def rules(db)
      db.tables.map do |table|
        columns = db[table].columns.map { |column| [column, rule(db, table, column)] }.to_h
        [table, columns]
      end.to_h
    end

    private

    # TODO Validate user input
    def source(name)
      @source_db_name = name
    end

    # TODO Validate user input
    def target(name)
      @target_db_name = name
    end

    def strategy(strategy = nil)
      return @strategy || :whitelist if strategy == nil

      unless %i(whitelist blacklist).include?(strategy)
        abort('Strategy should be one of :whitelist or :blacklist')
      end

      @strategy = strategy
    end

    def foreign_keys(db)
      @foreign_keys ||= Becloud::DBUtils.foreign_keys(db)
    end

    def rule(db, table, column)
      table_foreign_keys = foreign_keys(db)[table] || []
      if table_foreign_keys.include?(column) || strategy == :blacklist
        :keep
      else
        :anonymize
      end
    end
  end
end
