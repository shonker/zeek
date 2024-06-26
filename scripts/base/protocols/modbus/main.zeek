##! Base Modbus analysis script.

module Modbus;

@load ./consts

export {
	redef enum Log::ID += { LOG };

	global log_policy: Log::PolicyHook;

	type Info: record {
		## Time of the request.
		ts:        time           &log;
		## Unique identifier for the connection.
		uid:       string         &log;
		## Identifier for the connection.
		id:        conn_id        &log;
		## Modbus transaction ID
		tid:	   count         &log &optional;
		## The terminal unit identifier for the message
		unit:	   count         &log &optional;
		## The name of the function message that was sent.
		func:      string         &log &optional;
		## Whether this PDU was a response ("RESP") or request ("REQ")
		pdu_type:  string         &log &optional;
		## The exception if the response was a failure.
		exception: string         &log &optional;
	};

	## Event that can be handled to access the Modbus record as it is sent
	## on to the logging framework.
	global log_modbus: event(rec: Info);
}

redef record connection += {
	modbus: Info &optional;
};

const ports = { 502/tcp };
redef likely_server_ports += { ports };

event zeek_init() &priority=5
	{
	Log::create_stream(Modbus::LOG, [$columns=Info, $ev=log_modbus, $path="modbus", $policy=log_policy]);
	Analyzer::register_for_ports(Analyzer::ANALYZER_MODBUS, ports);
	}

event modbus_message(c: connection, headers: ModbusHeaders, is_orig: bool) &priority=5
	{
	if ( ! c?$modbus )
		{
		c$modbus = [$ts=network_time(), $uid=c$uid, $id=c$id];
		}

	c$modbus$ts   = network_time();
	c$modbus$tid = headers$tid;
	c$modbus$unit = headers$uid;
	c$modbus$func = function_codes[headers$function_code];
	## If this message is from the TCP originator, it is a request. Otherwise,
	## it is a response.
	c$modbus$pdu_type = is_orig ? "REQ" : "RESP";
	}

event modbus_message(c: connection, headers: ModbusHeaders, is_orig: bool) &priority=-5
	{
	# Don't log now if this is an exception (log in the exception event handler)
	if ( headers$function_code <= 0x81 || headers$function_code >= 0x98 )
		Log::write(LOG, c$modbus);
	}

event modbus_exception(c: connection, headers: ModbusHeaders, code: count) &priority=5
	{
	c$modbus$exception = exception_codes[code];
	}

event modbus_exception(c: connection, headers: ModbusHeaders, code: count) &priority=-5
	{
	Log::write(LOG, c$modbus);
	delete c$modbus$exception;
	}
