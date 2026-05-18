

const Lexer = @import("doclex").Lexer;
const testing = @import("std").testing;
const Tag = Lexer.Token.Tag;

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
