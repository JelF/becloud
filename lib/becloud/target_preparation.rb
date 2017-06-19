require 'tempfile'
require 'becloud/sequel'

module Becloud::TargetPreparation

  class << self

    # TODO Support all args in system commands (host, username, password, etc...)
    def with_prepared_target(source_db_name, target_db_name)
      dump_path = Tempfile.new.path

      run("pg_dump -s #{source_db_name} > #{dump_path}")
      run("dropdb --if-exists #{target_db_name}")
      run("createdb #{target_db_name}")
      run("psql #{target_db_name} < #{dump_path}")

      Becloud::Sequel.connect(target_db_name) { |db| yield db }
    end

    private

    def run(command)
      raise "Error while executing: #{command}" unless system(command)
    end
  end
end
