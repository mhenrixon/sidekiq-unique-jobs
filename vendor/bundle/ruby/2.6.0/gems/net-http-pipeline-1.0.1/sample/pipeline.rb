require 'net/http/pipeline'

http = Net::HTTP.new 'localhost'
http.set_debug_output $stderr # so you can see what is happening
# http.pipelining = true # set this when localhost:80 is an HTTP/1.1 server

http.start do |http|
  reqs = []
  reqs << Net::HTTP::Get.new('/?a') # this request will be non-pipelined
                                    # to check if localhost:80 is HTTP/1.1
                                    # unless http.pipelining == true
  reqs << Net::HTTP::Get.new('/?b') # these requests will be pipelined
  reqs << Net::HTTP::Get.new('/?c')

  http.pipeline reqs do |res|
    puts res.code
    puts res.body[0..60].inspect
    puts
  end
end

