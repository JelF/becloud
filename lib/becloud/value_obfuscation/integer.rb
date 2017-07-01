module Becloud::ValueObfuscation::Integer

  # TODO Implement
  def self.obfuscate(seed)
    if seed
      seed
    else
      (1..100).to_a.sample
    end
  end
end
