

const _ = @import("./Lexer.zig");
test "must be error" {
    try @import("std").testing.expectEqual(true, false);
}
