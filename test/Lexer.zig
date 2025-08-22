

const Lexer = @import("../src/Lexer.zig");
const testig = @import("std").testing;


test "line comment" {
    const lexer: Lexer = .{
        .with_doc = false,
        .buf = "//this is line comment",
    };

    try testing.expect(token.next() == Tag.eof);
    try testing.expectEqual(token.loc.beg, lexer.buf.len);
    try testing.expectEqual(token.loc.end, lexer.buf.len);
}
