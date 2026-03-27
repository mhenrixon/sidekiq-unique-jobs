# frozen_string_literal: true

module IconHelper
  def hero(name, **)
    unsafe_raw(
      Icons::Icon.new(
        name: name.to_s.dasherize,
        library: "heroicons",
        arguments: { ** },
      ).svg,
    )
  end
end
