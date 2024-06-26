# @TEST-REQUIRES: have-spicy
#
# @TEST-EXEC: spicyz -o test.hlto tupleenum.spicy ./tupleenum.evt
# @TEST-EXEC: zeek -r ${TRACES}/ssh/single-conn.trace test.hlto %INPUT Spicy::enable_print=T | sort >output
# @TEST-EXEC: btest-diff output

type Foo: record {
    i: TupleEnum::TestEnum;
    j: count;
};

event enum_message(f: Foo) {
	print f;
}

event zeek_init() {
	Analyzer::register_for_port(Analyzer::ANALYZER_TUPLEENUM, 22/tcp);
}

# @TEST-START-FILE tupleenum.evt

protocol analyzer TupleEnum over TCP:
    parse with TupleEnum::Message;

on TupleEnum::Message -> event enum_message( (self.a, cast<uint64>(self.b)) );

# @TEST-END-FILE

# @TEST-START-FILE tupleenum.spicy

module TupleEnum;

public type TestEnum = enum {
    A = 83, B = 84, C = 85
};

public type Message = unit {
    a: uint8 &convert=TestEnum($$);
    b: uint8;

    on %done { print self; }
};

# @TEST-END-FILE
