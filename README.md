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

    // The id that will be appended to the end of the ID to uniquely identify the node
    const node_id: u11 = 432;
    const kid = KID.init(node_id, .{});

    const id = kid.generate();

    // your code
    // ...
}
```

You can decode the ID for more detailed analysis or for log storage

```zig
    const node_id: u11 = 432;
    const kid = KID.init(node_id, .{});

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

Sorting the generated ids is fairly simple. Because of how the ID is structured, you can rely on it being packed in the same order
where you sort by timestamp->count->node_id

```zig

const ids = try allocator.alloc(u64, 100);
defer allocator.free(ids);

var kid = KID.init(10, .{});

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
            .url = "https://github.com/kobolds-io/kid/archive/refs/tags/v0.0.2.tar.gz",
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

It is pretty quick but probably not the fastest thing out there.

```plaintext
--------------------------------------------------------
  Operating System: linux x86_64
  CPU:              12th Gen Intel(R) Core(TM) i7-12700H
  CPU Cores:        14
  Total Memory:     31.021GiB
--------------------------------------------------------

|----------------|
| KID Benchmarks |
|----------------|
benchmark              runs     total time     time/run (avg ± σ)    (min ... max)                p75        p99        p995      
-----------------------------------------------------------------------------------------------------------------------------
generate 1 ids         100      4.829us        48ns ± 41ns           (42ns ... 456ns)             45ns       456ns      456ns     
generate 1000 ids      100      2.552ms        25.52us ± 955ns       (24.604us ... 29.312us)      25.881us   29.312us   29.312us  
generate 8192 ids      100      20.241ms       202.417us ± 7.911us   (194.825us ... 233.678us)    203.553us  233.678us  233.678us 
generate 10_000 ids    100      99.213ms       992.138us ± 76.048us  (240.061us ... 1.013ms)      1ms        1.013ms    1.013ms   
generate 100_000 ids   100      1.199s         11.999ms ± 7.714us    (11.967ms ... 12.019ms)      12.001ms   12.019ms   12.019ms  
generate 1_000_000 ids 5        609.893ms      121.978ms ± 46.345us  (121.895ms ... 121.999ms)    121.999ms  121.999ms  121.999ms 
```

