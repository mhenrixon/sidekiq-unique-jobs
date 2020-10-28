require 'test_helper'

class ToxiproxyTest < MiniTest::Unit::TestCase
  def teardown
    Toxiproxy.grep(/\Atest_/).each(&:destroy)
  end

  def test_create_proxy
    proxy = Toxiproxy.create(upstream: "localhost:3306", name: "test_mysql_master")

    assert_equal "localhost:3306", proxy.upstream
    assert_equal "test_mysql_master", proxy.name
  end

  def test_create_and_find_proxy
    proxy = Toxiproxy.create(upstream: "localhost:3306", name: "test_mysql_master")

    assert_equal "localhost:3306", proxy.upstream
    assert_equal "test_mysql_master", proxy.name

    proxy = Toxiproxy[:test_mysql_master]

    assert_equal "localhost:3306", proxy.upstream
    assert_equal "test_mysql_master", proxy.name
  end

  def test_proxy_not_running_with_bad_host
    Toxiproxy.host = 'http://0.0.0.0:12345'
    assert !Toxiproxy.running?, 'toxiproxy should not be running'
  ensure
    Toxiproxy.host = Toxiproxy::DEFAULT_URI
  end

  def test_enable_and_disable_proxy_with_toxic
    with_tcpserver do |port|
      proxy = Toxiproxy.create(upstream: "localhost:#{port}", name: "test_rubby_server")
      listen_addr = proxy.listen

      Toxiproxy::Toxic.new(type: 'latency', attributes: { latency: 123 }, proxy: proxy).save

      proxy.disable
      assert_proxy_unavailable proxy
      proxy.enable
      assert_proxy_available proxy

      latency = proxy.toxics.find { |toxic| toxic.name == 'latency_downstream' }

      assert_equal 123, latency.attributes['latency']
      assert_equal listen_addr, proxy.listen
    end
  end

  def test_delete_toxic
    with_tcpserver do |port|
      proxy = Toxiproxy.create(upstream: "localhost:#{port}", name: "test_rubby_server")
      listen_addr = proxy.listen

      latency = Toxiproxy::Toxic.new(type: 'latency', attributes: { latency: 123 }, proxy: proxy).save

      assert_proxy_available proxy

      latency = proxy.toxics.find { |toxic| toxic.name == 'latency_downstream' }
      assert_equal 123, latency.attributes['latency']

      latency.destroy

      assert proxy.toxics.empty?
      assert_equal listen_addr, proxy.listen
    end
  end

  def test_reset
    with_tcpserver do |port|
      proxy = Toxiproxy.create(upstream: "localhost:#{port}", name: "test_rubby_server")
      listen_addr = proxy.listen

      proxy.disable
      assert_proxy_unavailable proxy

      Toxiproxy::Toxic.new(type: 'latency', attributes: { latency: 123 }, proxy: proxy).save

      Toxiproxy.reset
      assert_proxy_available proxy

      assert proxy.toxics.empty?
      assert_equal listen_addr, proxy.listen
    end
  end

  def test_take_endpoint_down
    with_tcpserver do |port|
      proxy = Toxiproxy.create(upstream: "localhost:#{port}", name: "test_rubby_server")
      listen_addr = proxy.listen

      proxy.down do
        assert_proxy_unavailable proxy
      end

      assert_proxy_available proxy

      assert_equal listen_addr, proxy.listen
    end
  end

  def test_raises_when_proxy_doesnt_exist
    assert_raises Toxiproxy::NotFound do
      Toxiproxy[:does_not_exist]
    end
  end

  def test_proxies_all_returns_proxy_collection
    assert_instance_of Toxiproxy::ProxyCollection, Toxiproxy.all
  end

  def test_down_on_proxy_collection_disables_entire_collection
    with_tcpserver do |port1|
      with_tcpserver do |port2|
        proxy1 = Toxiproxy.create(upstream: "localhost:#{port1}", name: "test_proxy1")
        proxy2 = Toxiproxy.create(upstream: "localhost:#{port2}", name: "test_proxy2")

        assert_proxy_available proxy2
        assert_proxy_available proxy1

        Toxiproxy.all.down do
          assert_proxy_unavailable proxy1
          assert_proxy_unavailable proxy2
        end

        assert_proxy_available proxy2
        assert_proxy_available proxy1
      end
    end
  end

  def test_disable_on_proxy_collection
    with_tcpserver do |port1|
      with_tcpserver do |port2|
        proxy1 = Toxiproxy.create(upstream: "localhost:#{port1}", name: "test_proxy1")
        proxy2 = Toxiproxy.create(upstream: "localhost:#{port2}", name: "test_proxy2")

        assert_proxy_available proxy2
        assert_proxy_available proxy1

        Toxiproxy.all.disable
        assert_proxy_unavailable proxy1
        assert_proxy_unavailable proxy2
        Toxiproxy.all.enable

        assert_proxy_available proxy2
        assert_proxy_available proxy1
      end
    end
  end

  def test_select_from_toxiproxy_collection
    with_tcpserver do |port|
      Toxiproxy.create(upstream: "localhost:#{port}", name: "test_proxy")

      proxies = Toxiproxy.select { |p| p.upstream == "localhost:#{port}" }

      assert_equal 1, proxies.size
      assert_instance_of Toxiproxy::ProxyCollection, proxies
    end
  end

  def test_grep_returns_toxiproxy_collection
    with_tcpserver do |port|
      Toxiproxy.create(upstream: "localhost:#{port}", name: "test_proxy")

      proxies = Toxiproxy.grep(/\Atest/)

      assert_equal 1, proxies.size
      assert_instance_of Toxiproxy::ProxyCollection, proxies
    end
  end

  def test_indexing_allows_regexp
    with_tcpserver do |port|
      Toxiproxy.create(upstream: "localhost:#{port}", name: "test_proxy")

      proxies = Toxiproxy[/\Atest/]

      assert_equal 1, proxies.size
      assert_instance_of Toxiproxy::ProxyCollection, proxies
    end
  end

  def test_apply_upstream_toxic
    with_tcpserver(receive: true) do |port|
      proxy = Toxiproxy.create(upstream: "localhost:#{port}", name: "test_proxy")

      proxy.upstream(:latency, latency: 100).apply do
        before = Time.now

        socket = connect_to_proxy(proxy)
        socket.write("omg\n")
        socket.flush
        socket.gets

        passed = Time.now - before

        assert_in_delta passed, 0.100, 0.01
      end
    end
  end

  def test_apply_downstream_toxic
    with_tcpserver(receive: true) do |port|
      proxy = Toxiproxy.create(upstream: "localhost:#{port}", name: "test_proxy")

      proxy.downstream(:latency, latency: 100).apply do
        before = Time.now

        socket = connect_to_proxy(proxy)
        socket.write("omg\n")
        socket.flush
        socket.gets

        passed = Time.now - before

        assert_in_delta passed, 0.100, 0.01
      end
    end
  end

  def test_toxic_applies_a_downstream_toxic
    with_tcpserver(receive: true) do |port|
      proxy = Toxiproxy.create(upstream: "localhost:#{port}", name: "test_proxy")

      proxy.toxic(:latency, latency: 100).apply do
        latency = proxy.toxics.find { |toxic| toxic.name == 'latency_downstream' }

        assert_equal 100, latency.attributes['latency']
        assert_equal 'downstream', latency.stream
      end
    end
  end

  def test_toxic_default_name_is_type_and_stream
    toxic = Toxiproxy::Toxic.new(type: "latency", stream: "downstream")
    assert_equal "latency_downstream", toxic.name
  end

  def test_apply_prolong_toxics
    with_tcpserver(receive: true) do |port|
      proxy = Toxiproxy.create(upstream: "localhost:#{port}", name: "test_proxy")

      proxy.upstream(:latency, latency: 100).downstream(:latency, latency: 100).apply do
        before = Time.now

        socket = connect_to_proxy(proxy)
        socket.write("omg\n")
        socket.flush
        socket.gets

        passed = Time.now - before

        assert_in_delta passed, 0.200, 0.01
      end
    end
  end

  def test_apply_toxics_to_collection
    with_tcpserver(receive: true) do |port1|
      with_tcpserver(receive: true) do |port2|
        proxy1 = Toxiproxy.create(upstream: "localhost:#{port1}", name: "test_proxy1")
        proxy2 = Toxiproxy.create(upstream: "localhost:#{port2}", name: "test_proxy2")

        Toxiproxy[/test_proxy/].upstream(:latency, latency: 100).downstream(:latency, latency: 100).apply do
          before = Time.now

          socket = connect_to_proxy(proxy1)
          socket.write("omg\n")
          socket.flush
          socket.gets

          passed = Time.now - before

          assert_in_delta passed, 0.200, 0.01

          before = Time.now

          socket = connect_to_proxy(proxy2)
          socket.write("omg\n")
          socket.flush
          socket.gets

          passed = Time.now - before

          assert_in_delta passed, 0.200, 0.01
        end
      end
    end
  end

  def test_populate_creates_proxies_array
    proxies = [{
        name: "test_toxiproxy_populate1",
        upstream: "localhost:3306",
        listen: "localhost:22222",
      },
      {
        name: "test_toxiproxy_populate2",
        upstream: "localhost:3306",
        listen: "localhost:22223",
      },
    ]

    proxies = Toxiproxy.populate(proxies)

    proxies.each do |proxy|
      assert_proxy_available(proxy)
    end
  end

  def test_populate_creates_proxies_args
    proxies = [{
        name: "test_toxiproxy_populate1",
        upstream: "localhost:3306",
        listen: "localhost:22222",
      },
      {
        name: "test_toxiproxy_populate2",
        upstream: "localhost:3306",
        listen: "localhost:22223",
      },
    ]

    proxies = Toxiproxy.populate(*proxies)

    proxies.each do |proxy|
      assert_proxy_available(proxy)
    end
  end

  def test_populate_creates_proxies_update_listen
    proxies = [{
        name: "test_toxiproxy_populate1",
        upstream: "localhost:3306",
        listen: "localhost:22222",
      },
    ]

    proxies = Toxiproxy.populate(proxies)

    proxies = [{
        name: "test_toxiproxy_populate1",
        upstream: "localhost:3306",
        listen: "localhost:22223",
      },
    ]

    proxies = Toxiproxy.populate(proxies)

    proxies.each do |proxy|
      assert_proxy_available(proxy)
    end
  end

  def test_populate_creates_proxies_update_upstream
    proxies = [{
        name: "test_toxiproxy_populate1",
        upstream: "localhost:3306",
        listen: "localhost:22222",
      },
    ]

    proxies = Toxiproxy.populate(proxies)

    proxies = [{
        name: "test_toxiproxy_populate1",
        upstream: "localhost:3307",
        listen: "localhost:22222",
      },
    ]

    proxies2 = Toxiproxy.populate(proxies)

    assert_equal proxies.first[:upstream], proxies2.first.upstream
    assert_proxy_available(proxies2.first)
  end

  def test_running_helper
    assert_equal true, Toxiproxy.running?
  end

  def test_version
    assert_instance_of String, Toxiproxy.version
  end

  def test_multiple_of_same_toxic_type
    with_tcpserver(receive: true) do |port|
      proxy = Toxiproxy.create(upstream: "localhost:#{port}", name: "test_proxy")
      proxy.toxic(:latency, latency: 100).toxic(:latency, latency: 100, name: "second_latency_downstream").apply do
        before = Time.now

        socket = connect_to_proxy(proxy)
        socket.write("omg\n")
        socket.flush
        socket.gets

        passed = Time.now - before

        assert_in_delta passed, 0.200, 0.01
      end
    end
  end

  def test_multiple_of_same_toxic_type_with_same_name
    with_tcpserver(receive: true) do |port|
      proxy = Toxiproxy.create(upstream: "localhost:#{port}", name: "test_proxy")

      assert_raises ArgumentError do
        proxy.toxic(:latency, latency: 100).toxic(:latency, latency: 100).apply { }
      end
    end
  end

  def test_invalid_direction
    with_tcpserver(receive: true) do |port|
      proxy = Toxiproxy.create(upstream: "localhost:#{port}", name: "test_rubby_server")

      assert_raises Toxiproxy::InvalidToxic do
        Toxiproxy::Toxic.new(type: 'latency', attributes: { latency: 123 }, proxy: proxy, stream: 'lolstream').save
      end
    end
  end

  def test_whitelists_webmock_when_allow_is_nil
    with_webmock_enabled do
      WebMock::Config.instance.allow = nil
      Toxiproxy.version # This should initialize the list.
      assert WebMock::Config.instance.allow.include?(@endpoint)
    end
  end

  def test_whitelisting_webmock_does_not_override_other_configuration
    with_webmock_enabled do
      WebMock::Config.instance.allow = ['some-other-host']
      Toxiproxy.version
      # 'some-other-host' should not be overriden.
      assert WebMock::Config.instance.allow.include?('some-other-host')
      assert WebMock::Config.instance.allow.include?(@endpoint)

      Toxiproxy.version
      # Endpoint should not be duplicated.
      assert_equal 1, WebMock::Config.instance.allow.count(@endpoint)
    end
  end

  private

  def with_webmock_enabled
    WebMock.enable!
    WebMock.disable_net_connect!
    @endpoint = "#{Toxiproxy.uri.host}:#{Toxiproxy.uri.port}"
    yield
  ensure
    WebMock.disable!
  end

  def assert_proxy_available(proxy)
    connect_to_proxy proxy
  end

  def assert_proxy_unavailable(proxy)
    assert_raises Errno::ECONNREFUSED do
      connect_to_proxy proxy
    end
  end

  def connect_to_proxy(proxy)
    TCPSocket.new(*proxy.listen.split(":".freeze))
  end

  def with_tcpserver(receive = false, &block)
    mon = Monitor.new
    cond = mon.new_cond
    port = nil

    thread = Thread.new {
      server = TCPServer.new("127.0.0.1", 0)
      port = server.addr[1]
      mon.synchronize { cond.signal }
      loop do
        client = server.accept

        if receive
          client.gets
          client.write("omgs\n")
          client.flush
        end

        client.close
      end
      server.close
    }

    mon.synchronize { cond.wait }

    yield(port)
  ensure
    thread.kill
  end
end
