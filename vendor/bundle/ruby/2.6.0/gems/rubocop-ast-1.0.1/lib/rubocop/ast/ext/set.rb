# frozen_string_literal: true

test = :foo
case test
when Set[:foo]
  # ok, RUBY_VERSION > 2.4
else
  # Harmonize `Set#===`
  class Set
    alias === include?
  end
end
