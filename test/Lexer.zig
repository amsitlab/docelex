

const Lexer = @import("../src/Lexer.zig");
const testing = @import("std").testing;
const Tag = Lexer.Token.Tag;

test "line comment" {
    const lexer: Lexer = .{
        .with_doc = false,
        .buf = "//this is line comment",
    };
    const token = lexer.next();
    try testing.expect(token.next() == Tag.eof);
    try testing.expectEqual(token.loc.beg, lexer.buf.len);
    try testing.expectEqual(token.loc.end, lexer.buf.len);
}
