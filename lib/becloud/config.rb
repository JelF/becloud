module Becloud::Config

  class << self

    def load_config(path)
      raise 'Obfuscation config path not specified' if !path || path.empty?
      config = File.read(File.expand_path(path, Dir.pwd))
      eval(config)
      self
    end

    def source_db(**opts)
      if opts.empty?
        @source_db
      else
        @source_db = opts
      end
    end

    def destination_db(**opts)
      if opts.empty?
        @destination_db
      else
        @destination_db = opts
      end
    end
  end
end
