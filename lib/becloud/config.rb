module Becloud::Config

  class << self

    def load_config(path)
      raise 'Obfuscation config path not specified' if !path || path.empty?
      config = File.read(File.expand_path(path, Dir.pwd))
      eval(config)
      self
    end

    def source(**opts)
      if opts.empty?
        @source
      else
        @source = opts
      end
    end

    def target(**opts)
      if opts.empty?
        @target
      else
        @target = opts
      end
    end
  end
end
