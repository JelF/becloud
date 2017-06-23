require 'tempfile'
require 'becloud/sequel'

module Becloud::TargetUtils

  class << self

    # TODO Support all args in system commands (host, username, password, etc...)
    def reset_target_schema(source_db_name, target_db_name)
      dump_path = Tempfile.new.path

      run("pg_dump -s #{source_db_name} > #{dump_path}")
      run("dropdb --if-exists #{target_db_name}")
      run("createdb #{target_db_name}")
      run("psql #{target_db_name} < #{dump_path}")
    end

    def remove_foreign_keys(db)
      db.tables.each do |table|
        db.foreign_key_list(table).each do |foreign_key|
          db.alter_table(table) do
            drop_foreign_key(foreign_key[:columns], name: foreign_key[:name])
          end
        end
      end
    end

    private

    def run(command)
      raise "Error while executing: #{command}" unless system(command)
    end
  end
end
