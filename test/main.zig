

const _ = @import("./Lexer.zig");
test "must be error" {
    @import("std").testing.expectEqual(true, false);
}
