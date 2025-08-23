

// Field(s) of lexer
/// the source buffer
buf: [:0]const u8,
/// the index of source
idx: usize = 0,
///
with_doc: bool = false,

pub const Token = struct {
//{{{1
    /// Tag of token
    tag: Tag,
    /// Location of token.
    loc: Loc,

    pub const Loc = struct {
        /// begin location.
        beg: usize,
        /// end location
        end: usize,
    };

    
    pub const Tag = enum {
    //{{{2
        
        key_and,
        key_break,

        literal_number,

        ampersand,
        astrisk,
        astrisk2x,
        bang,
        comment,
        doc,
        doc_container,
        slash,
        slash_equal,

        illegal,
        eof,

    //}}}2
    };

//}}}1
};

const State = enum {

    start,
    slash,
    invalid,
    comment_line,
    comment_line_start,
    doc_or_comment_stop,
    doc,
    doc_start,
    int,
    number_hex,
};


pub fn next(it: *@This()) Token {
    var token: Token = .{
        .tag = .eof, .loc = .{
            .beg = it.idx, .end = it.idx
        }
    };
    var doc_len: usize = 0;
    var is_zero_based = false;
    const BUFLEN = it.buf.len;
    state: switch(State.start) {
        .start => switch(it.buf[it.idx]){
        //{{{1
            0 => if(it.idx == BUFLEN) {
                token.tag = .eof;
                token.loc.end = it.idx;
                return token;
            } else {
                //it.idx += 1;
                token.tag = .illegal;
                continue :state .invalid;
            },
            ' ', '\t', '\r', '\n' => {
                it.idx += 1;
                token.loc.beg = it.idx;
                token.loc.end = it.idx;
                continue :state .start;
            },
            '/' => continue :state .slash,
            else => if (it.idx != BUFLEN) {
                continue :state .invalid;
            } else {
                token.tag = .eof;
                token.loc.end = it.idx;
                return token;
            },
            '0'...'9' => {
                token.tag = .literal_number;
                is_zero_based = it.buf[it.idx] == '0';
                it.idx += 1;
                continue :state .int;
            }
        //}}}1
        },
        .slash => {
        //{{{1
            it.idx += 1;
            switch(it.buf[it.idx]) {
                0 =>  if(it.idx != BUFLEN) {
                    continue :state .invalid;
                } else {
                    token.tag = .eof;
                    token.loc.end = it.idx;
                    return token;
                },
                //'!' => continue :state .doc_start,
                '/' => {
                    it.idx += 1;
                    switch(it.buf[it.idx]) {
                        0 => if(it.idx == BUFLEN){
                            token.tag = .eof;
                            token.loc.end = it.idx;
                            return token;
                        } else {
                            continue :state .invalid;
                        },
                        else => continue :state .comment_line,
                    }   
                },
                '=' => {
                    it.idx += 1;
                    token.tag = .slash_equal;
                },
                '*' => continue :state .doc_start,
                else => token.tag = .slash,
            }
        //}}}1
        },
        .invalid => {
        //{{{1
            it.idx += 1;
            switch(it.buf[it.idx]) {
                0 => if(it.idx == BUFLEN) {
                    token.tag = .illegal;
                } else {
                    continue :state .invalid;
                },
                '\n' => token.tag = .illegal,
                else => continue :state .invalid,
            }
        //}}}1
        },
        .comment_line_start => {
        //{{{1
        //}}}1
        },
        .comment_line => {
        //{{{1
            it.idx += 1;
            switch(it.buf[it.idx]) {
                0 => if(it.idx == BUFLEN) {
                    token.tag = .eof;
                    token.loc.end = it.idx;
                    return token;
                } else {
                    continue :state .invalid;
                },
                '*' => continue :state .doc_or_comment_stop,
                '\n' => {
                    
                    it.idx += 1;
                    token.loc.beg = it.idx;
                    token.loc.end = it.idx;
                    continue :state .start;
                },
                else => continue :state .comment_line,
            }
            
        //}}}1
        },
        .doc_start => {
        //{{{1
            it.idx += 1;
            token.tag = .doc;
            switch(it.buf[it.idx]) {
                0 => if (it.idx != BUFLEN) {
                    continue :state .invalid;
                } else {
                    token.tag = .eof;
                },
                '!' => {
                    //it.idx += 1;
                    token.tag = .doc_container;
                    continue :state .doc;
                },
                '*' => continue :state .doc_or_comment_stop,
                else => {
                    doc_len += 1; // for .doc
                    continue :state .doc;
                },
            }
        //}}}1
        },
        .doc => {
        //{{{1
            it.idx += 1;
            switch(it.buf[it.idx]) {
                0 => if(it.idx != BUFLEN) {
                    continue :state .invalid;
                } else {
                    token.tag = .illegal;
                },
                '*' => continue :state .doc_or_comment_stop,
                else => {
                    doc_len += 1;
                    continue :state .doc;
                },
            }
        //}}}1
        },
        .doc_or_comment_stop => {
        //{{{1
            it.idx += 1;
            switch(it.buf[it.idx]) {
                0 => if(it.idx == BUFLEN) {
                    token.tag = .eof;
                } else {
                    continue :state .invalid;
                },
                '/' => {
                    it.idx += 1;
                    if (doc_len == 0 or it.with_doc == false) {
                        continue :state .start;
                    }
                },
                else => switch(token.tag) {
                    .doc, .doc_container => continue :state .doc,
                    .comment => continue :state .comment_line,
                    else => {},
                },
            }
        //}}}1
        },
        .int => switch(it.buf[it.idx]){
        //{{{1
            // TODO: floating-point, integer-exponent
            '_',
            '0'...'9' => {
                it.idx += 1;
                continue :state .int;
            },
            'x', 'X' => if (is_zero_based) {
                it.idx += 1;
                continue :state .number_hex;
            } else {
                if (it.idx != BUFLEN) continue :state .invalid;
                token.tag = .illegal;
                token.loc.end = it.idx;
                return token;
            },
            //TODO: B b for binary 
            //TODO: E e for exponent
            //TODO: O o for octal
            //TODO: P p for hexa-exponent
            'a', 'A',
            'c', 'C',
            'd', 'D',
            'f'...'n', 'F'...'N',
            'q'...'w', 'Q'...'W',
            'y', 'Y',
            'z', 'Z' => continue :state .invalid,
        //}}}1
        },
        .number_hex => switch(it.buf[it.idx]){
            0 => if(it.idx == BUFLEN) {
                token.tag = .illegal;
                token.loc.end = it.idx;
                return token;
            } else {
                continue :state .invalid;
            },
            'a'...'f', 'A'...'F', '0'...'9', '_' => {
                it.idx += 1;
                continue :state .number_hex;
            },
            else => {},
        }
    }
    
    token.loc.end = it.idx;
    return token;
}

