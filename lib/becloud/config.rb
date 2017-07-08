# frozen_string_literal: true

require 'becloud/db_utils'

module Becloud::Config

  class << self

    attr_reader :source_db_name
    attr_reader :target_db_name

    # TODO Eval config in a separate object context
    def load_config(path)
      abort('Obfuscation config path not specified') if !path || path.empty?
      config_path = File.expand_path(path, Dir.pwd)
      instance_eval(File.read(config_path), config_path)
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

    # TODO Validate value is present and correct
    def source(name)
      @source_db_name = name
    end

    # TODO Validate value is present and correct
    def target(name)
      @target_db_name = name
    end

    def strategy(strategy = nil)
      return @strategy || :whitelist if strategy == nil

      unless %i(whitelist blacklist).include?(strategy)
        raise(StandardError, 'Strategy should be one of :whitelist or :blacklist', caller(1))
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
