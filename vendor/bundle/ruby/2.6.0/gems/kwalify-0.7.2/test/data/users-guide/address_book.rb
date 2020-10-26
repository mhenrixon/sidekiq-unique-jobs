## address-book class
class AddressBook
  def initialize(hash=nil)
    if hash.nil?
      return
    end
    @groups           = (v=hash['groups']) ? v.map!{|e| e.is_a?(Group) ? e : Group.new(e)} : v
    @people           = (v=hash['people']) ? v.map!{|e| e.is_a?(Person) ? e : Person.new(e)} : v
  end
  attr_accessor :groups           # seq
  attr_accessor :people           # seq
end

## group class
class Group
  def initialize(hash=nil)
    if hash.nil?
      return
    end
    @name             = hash['name']
    @desc             = hash['desc']
  end
  attr_accessor :name             # str
  attr_accessor :desc             # str
end

## person class
class Person
  def initialize(hash=nil)
    if hash.nil?
      @deleted          = false
      return
    end
    @name             = hash['name']
    @desc             = hash['desc']
    @group            = hash['group']
    @email            = hash['email']
    @phone            = hash['phone']
    @birth            = hash['birth']
    @blood            = hash['blood']
    @deleted          = (v=hash['deleted']).nil? ? false : v
  end
  attr_accessor :name             # str
  attr_accessor :desc             # str
  attr_accessor :group            # str
  attr_accessor :email            # str
  attr_accessor :phone            # str
  attr_accessor :birth            # date
  attr_accessor :blood            # str
  attr_accessor :deleted          # bool
  def deleted?      ;  @deleted      ; end
end
