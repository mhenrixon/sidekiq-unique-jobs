local key_one = KEYS[1]
local key_two = KEYS[2]
local key_tre = KEYS[3]
local key_for = KEYS[4]
local key_fiv = KEYS[5]
local arg_one = ARGV[1]
local arg_two = ARGV[2]
local arg_tre = ARGV[3]
local arg_for = ARGV[4]
local arg_fiv = ARGV[5]


--------  BEGIN local functions --------
<%= include_partial "shared/_common.lua" %>
----------  END local functions ----------

---------  BEGIN test.lua ---------
log_debug("BEGIN test key:", key_one, "arg_one:", arg_one)

log_debug("SET", key_one, arg_one, "ex", 10)
redis.call("SET", key_one, arg_one, "ex", 10)

log_debug("SET", key_two, arg_two, "ex", 10)
redis.call("SET", key_two, arg_two, "ex", 10)

log_debug("SET", key_tre, arg_tre, "ex", 10)
redis.call("SET", key_tre, arg_tre, "ex", 10)

log_debug("SET", key_for, arg_for, "ex", 10)
redis.call("SET", key_for, arg_for, "ex", 10)

log_debug("SET", key_fiv, arg_fiv, "ex", 10)
redis.call("SET", key_fiv, arg_fiv, "ex", 10)

log_debug("END test key:", key_one, "arg_one:", arg_one)

return arg_for
----------  END test.lua  ----------
