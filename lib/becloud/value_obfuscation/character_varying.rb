module Becloud::ValueObfuscation::CharacterVarying

  # TODO Implement
  def self.obfuscate(seed)
    if seed
      "Hello World #{seed}"
    else
      "Random string"
    end
  end
end
