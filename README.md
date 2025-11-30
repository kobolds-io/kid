# KID

> **CAUTION** this project has been archived. Please see https://codeberg.org/kobolds-io/kid. See https://github.com/kobolds-io/kobolds/blob/main/migrating.md for details

KID (kobolds-id) is heavily influenced by Twitter snowflake id. It uses a fairly simple structure to guarantee uniqness. It is stored as an unsigned 64 bit integer that makes use of the system clock, a node identifier and a counter.

## Usage

Using `kid` is just as simple as using any other `zig` dependency.

```zig
// import the library into your file
const kid = @import("kid");

fn main() !void {
    // your code
    // ....

    // The id that will be appended to the end of the ID to uniquely identify the node
    const node_id: u11 = 432;
    kid.configure(node_id, .{});

    const id = kid.generate();

    // your code
    // ...
}
```

You can decode the ID for more detailed analysis or for log storage

```zig
    const node_id: u11 = 432;
    kid.configure(node_id, .{});

    const id = kid.generate();

    const decoded = kid.decode(id);


    // the decoded struct is just the expanded ID
    // const Decoded = struct {
    //     timestamp_ms: u64,
    //     counter: u32,
    //     node_id: u16,
    // };
    log.debug("decoded id: {any}", .{decoded});

```

Sorting the generated ids is fairly simple. Because of how the ID is structured, you can rely on it being packed in the same order where you sort by timestamp->count->node_id

```zig

const ids = try allocator.alloc(u64, 100);
defer allocator.free(ids);

// imagine this is randomized
for (0..ids.len) |i| {
    ids[i] = kid.generate();
}

// Use the std lib to sort
std.mem.sort(u64, ids, {}, std.sort.asc(u64))
```

## Installation

You can install `stdx` just like any other `zig` dependency by editing your `build.zig.zon` file.

```zig
    .dependencies = .{
        .kid = .{
            .url = "https://github.com/kobolds-io/kid/archive/refs/tags/v0.0.3.tar.gz",
            .hash = "",
        },
    },
```

run `zig build --fetch` to fetch the dependencies. This will return an error as the has will not match. Copy the new hash and try again.Sometimes `zig` is helpful and it caches stuff for you in the `zig-cache` dir. Try deleting that directory if you see some issues.

In your `build.zig` file add the library as a dependency.

```zig
// ...boilerplate

const kid_dep = b.dependency("kid", .{
    .target = target,
    .optimize = optimize,
});
const kid_mod = kid_dep.module("kid");

exe.root_module.addImport("kid", kid_mod);
```

## Benchmarks

It is pretty quick but probably not the fastest thing out there. There are some major optimizations that can be implemented.

```plaintext
--------------------------------------------------------
  Operating System: linux x86_64
  CPU:              13th Gen Intel(R) Core(TM) i9-13900K
  CPU Cores:        24
  Total Memory:     23.299GiB
--------------------------------------------------------

|----------------|
| KID Benchmarks |
|----------------|
benchmark              runs     total time     time/run (avg ± σ)    (min ... max)                p75        p99        p995
-----------------------------------------------------------------------------------------------------------------------------
generate 1 ids         100      4.326us        43ns ± 36ns           (38ns ... 403ns)             39ns       403ns      403ns
generate 1000 ids      100      11.824ms       118.244us ± 255.596us (23.107us ... 833.448us)     23.98us    833.448us  833.448us
generate 8192 ids      100      99.937ms       999.372us ± 12.833us  (941.086us ... 1.087ms)      1ms        1.087ms    1.087ms
generate 10_000 ids    100      121.945ms      1.219ms ± 334.773us   (989.662us ... 1.863ms)      1.056ms    1.863ms    1.863ms
generate 100_000 ids   100      1.22s          12.2ms ± 327.839us    (11.629ms ... 12.849ms)      12.076ms   12.849ms   12.849ms
generate 1_000_000 ids 5        635.875ms      127.175ms ± 11.603ms  (121.93ms ... 147.931ms)     122.009ms  147.931ms  147.931ms

|--------------------|
| uuid.v7 Benchmarks |
|--------------------|
benchmark              runs     total time     time/run (avg ± σ)    (min ... max)                p75        p99        p995
-----------------------------------------------------------------------------------------------------------------------------
uuid.v7 1 ids          100      11.198us       111ns ± 717ns         (36ns ... 7.215us)           38ns       7.215us    7.215us
uuid.v7 1000 ids       100      2.385ms        23.857us ± 2.125us    (23.052us ... 34.148us)      23.221us   34.148us   34.148us
uuid.v7 8192 ids       100      19.468ms       194.687us ± 11.031us  (189.236us ... 262.535us)    193.658us  262.535us  262.535us
uuid.v7 10_000 ids     100      23.74ms        237.405us ± 15.721us  (231.002us ... 353.901us)    236.285us  353.901us  353.901us
uuid.v7 100_000 ids    100      241.128ms      2.411ms ± 144.497us   (2.321ms ... 3.325ms)        2.418ms    3.325ms    3.325ms
uuid.v7 1_000_000 ids  5        120.516ms      24.103ms ± 732.673us  (23.432ms ... 25.246ms)      24.356ms   25.246ms   25.246ms

|--------------------|
| uuid.v4 Benchmarks |
|--------------------|
benchmark              runs     total time     time/run (avg ± σ)    (min ... max)                p75        p99        p995
-----------------------------------------------------------------------------------------------------------------------------
uuid.v4 1 ids          100      2.484us        24ns ± 23ns           (19ns ... 192ns)             20ns       192ns      192ns
uuid.v4 1000 ids       100      743.067us      7.43us ± 793ns        (7.249us ... 13.897us)       7.361us    13.897us   13.897us
uuid.v4 8192 ids       100      6.429ms        64.298us ± 15.015us   (54.129us ... 171.768us)     61.291us   171.768us  171.768us
uuid.v4 10_000 ids     100      7.621ms        76.216us ± 9.973us    (72.672us ... 140.729us)     74.412us   140.729us  140.729us
uuid.v4 100_000 ids    100      76.153ms       761.537us ± 79.077us  (726.534us ... 1.273ms)      752.914us  1.273ms    1.273ms
uuid.v4 1_000_000 ids  5        38.277ms       7.655ms ± 447.905us   (7.424ms ... 8.455ms)        7.483ms    8.455ms    8.455ms
```
