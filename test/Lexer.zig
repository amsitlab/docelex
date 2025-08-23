

const Lexer = @import("../src/Lexer.zig");
const testing = @import("std").testing;
const Tag = Lexer.Token.Tag;


fn lex(source: [:0]const u8, with_doc: bool) Lexer {
    return .{
        .buf = source, .with_doc = with_doc,
    };
}


test "line comment" {
    const lexer: Lexer = .{
        .with_doc = false,
        .buf = "//this is line comment",
    };
    const token = lexer.next();
    try testing.expect(token.tag == Tag.eof);
    try testing.expectEqual(token.loc.beg, lexer.buf.len);
    try testing.expectEqual(token.loc.end, lexer.buf.len);
}

test "line comment with close" {
    const lexer: Lexer = .{
        .with_doc = false,
        .buf = "//this is line comment*/",
    };
    const token = lexer.next();
    try testing.expect(token.tag == Tag.eof);
    try testing.expectEqual(token.loc.beg, lexer.buf.len);
    try testing.expectEqual(token.loc.end, lexer.buf.len);
}

test "line comment with close then illegal" {
    const lexer: Lexer = .{
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

test "basic number" {
    const lexer: Lexer = .{
        .whit_doc = false,
        .buf = "5"
    };

    var token = lexer.next();
    try testing.expectEqual(token.tag, Tag.literal_number);
    token = lexer.next();
    try testing.expectEqual(token.tag, Tag.eof);

}

test "hex number" {
    const lexer = lex("0xcafebabe", false);
    var token = lexer.next();
    try testing.expectEqual(token.tag, Tag.literal_number);
    const slice: []const u8 = lexer.buf[token.loc.beg..token.loc.end]; 
    try testing.expectEqual(slice, "0xcafebabe");
    token = lexer.next();
    try testing.expectEqual(token.tag, Tag.eof);
}

test "invalid number" {
    const lexer = lex("1e");
    try testing.expectEqual(lexer.next().tag, Tag.Illegal);
    try testing.expectEqual(lexer.next().tag, Tag.illegal);
}


