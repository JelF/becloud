module Becloud::ValueObfuscation::TimestampWithoutTimeZone

  # TODO Implement
  def self.obfuscate(_seed)
    Time.now
  end
end
