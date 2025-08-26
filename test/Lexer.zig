

const Lexer = @import("docelex").Lexer;
const literal = @import("docelex").literal;
const std = @import("std");
const testing = std.testing;
const Tag = Lexer.Token.Tag;


fn lex(source: [:0]const u8, with_doc: bool) Lexer {
    return .{
        .buf = source, .with_doc = with_doc,
    };
}


test "line comment" {
    var lexer: Lexer = .{
        .with_doc = false,
        .buf = "//this is line comment\n",
    };
    const token = lexer.next();
    try testing.expect(token.tag == Tag.eof);
    try testing.expectEqual(token.loc.beg, lexer.buf.len);
    try testing.expectEqual(token.loc.end, lexer.buf.len);
}

test "line comment with close" {
    var lexer: Lexer = .{
        .with_doc = false,
        .buf = "//this is line comment*/",
    };
    const token = lexer.next();
    try testing.expect(token.tag == Tag.eof);
    try testing.expectEqual(token.loc.beg, lexer.buf.len);
    try testing.expectEqual(token.loc.end, lexer.buf.len);
}

test "line comment with close then illegal" {
    var lexer: Lexer = .{
        .with_doc = false,
        .buf = "//this is line comment*/ illegal",
    };
    var token = lexer.next();
    try testing.expect(token.tag == Tag.illegal);
    const loc = token.loc;
    token = lexer.next();
    try testing.expect(token.tag == Tag.eof);
    try testing.expectEqual(loc.end, token.loc.beg);
    try testing.expectEqual(token.loc.end, lexer.buf.len);
}

test "line comment, doc comment, container doc comment" {
    const code = 
        \\ // This will be skipped
        \\ // Also this */
        \\ /*! This is container doc comment */
        \\ /* This is doc comment */
        ;
    var lexer: Lexer = .{
        .buf = code,
        .with_doc = code,
    };

    var token = lexer.next();
    testing.expectEqual(Tag.doc_container, token.tag);
    token = lexer.next();
    testing.expectEqual(Tag.doc, token.tag);
}

test "basic number" {
    var lexer: Lexer = .{
        .with_doc = false,
        .buf = "5 "
    };

    var token = lexer.next();
    std.debug.print("\n-----<basic number>-----\n", .{});
    _ = testing.expectEqual(Tag.literal_number, token.tag) catch |e| {
        std.debug.print("{}: Tag.literal_number == {?}\n", .{
            e, token.tag
        });
        std.debug.print("beg: {d}, end: {d}, slice: {s}\n", .{
            token.loc.beg, token.loc.end,
            lexer.buf[token.loc.beg..token.loc.end]
        });
        return e;
    };
    token = lexer.next();
    _ = testing.expectEqual(Tag.eof, token.tag) catch |e| {
        std.debug.print("{}: Tag.eof == {?}\n", .{
            e, token.tag
        });
        return e;
    };
    std.debug.print("\n-----</basic number>-----\n", .{});

}

test "hex number" {
    var lexer = lex("0xcafebabe\n", false);
    var token = lexer.next();
    const slice: []const u8 = lexer.buf[token.loc.beg..token.loc.end];
    std.debug.print("\n-----<hex number>-----\n", .{});
    _ = testing.expectEqual(Tag.literal_number, token.tag) catch |e| {
        std.debug.print("{}: Tag.literal_number == {?}\n", .{
            e, token.tag
        });
        return e;
    };
    _ = testing.expect(std.mem.eql(u8, "0xcafebabe", slice)) catch |e| {
        std.debug.print("{}: 0xcafebabe == {s}\nslice: {s}\n", .{
            e, slice, slice
        });
        return e;
    };
   
    token = lexer.next();
    _ = testing.expectEqual(Tag.eof, token.tag) catch |e| {
        std.debug.print("{}: Tag.eof == {?}\n", .{
            e, token.tag
        });
        return e;
    };
    std.debug.print("\n-----</hex number>-----\n", .{});
}

test "invalid number" {
    var lexer = lex("1e", false);
    var token = lexer.next();
    try testing.expectEqual(Tag.literal_number, token.tag);
    switch(literal.validateNumberLiteral("1e")) {
        .failure => |e| switch(e) {
            .upper_case_base,
            .repeated_underscore,
            .invalid_float_base,
            .invalid_underscore_after_special,
            //.invalid_digit,
            .invalid_digit_exponent,
            //.duplicate_period,
            .duplicate_exponent,
            .exponent_after_underscore,
            .special_after_underscore,
            .trailing_special,
            .trailing_underscore,
            .invalid_character,
            .invalid_exponent_sign,
            .period_after_exponent => |i| {
                std.debug.print("Malformed Number: at {d}", .{i});
            },
            else => {},
        },
        else => {},
    }

    std.debug.print("\nToken{{ .tag = {?}, .loc = {{ .beg = {d}, .end = {d} }} lex: {s}\n", .{
        token.tag, token.loc.beg, token.loc.end,
        lexer.buf[token.loc.beg..token.loc.end]
    });
    token = lexer.next();
    try testing.expectEqual(token.tag, Tag.eof);
}


