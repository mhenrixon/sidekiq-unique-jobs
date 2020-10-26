require 'kwalify/util/hashlike'

module Babel

  ## 
  class Team
    include Kwalify::Util::HashLike
    attr_accessor :name             # str
    attr_accessor :desc             # str
    attr_accessor :chief            # map
    attr_accessor :members          # seq
  end

  ## 
  class Member
    include Kwalify::Util::HashLike
    attr_accessor :name             # str
    attr_accessor :desc             # str
    attr_accessor :team             # map
  end

end
