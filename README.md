# KID

KID (kobolds-id) is heavily influenced by Twitter snowflake id. It uses a fairly simple structure to guarantee uniqness. It is stored as an unsigned 64 bit integer that makes use of the system clock, a node identifier and a counter.

## Usage

Using `kid` is just as simple as using any other `zig` dependency.

```zig
// import the library into your file
const kid = @import("kid");

fn main() !void {
    // your code
    // ....

    const node_id: u11 = 432;
    const kid = KID.init(node_id, .{});

    const id = kid.generate();

    // your code
    // ...
}

```
