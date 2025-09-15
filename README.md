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

var kid = KID.init(10);

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
generate 1 ids         100      54.486us       544ns ± 129ns         (515ns ... 1.813us)          544ns      1.813us    1.813us   
generate 1000 ids      100      20.949ms       209.491us ± 19.37us   (196.753us ... 295.863us)    211.772us  295.863us  295.863us 
generate 8192 ids      100      167.531ms      1.675ms ± 144.424us   (1.514ms ... 2.32ms)         1.699ms    2.32ms     2.32ms    
generate 10_000 ids    100      204.087ms      2.04ms ± 176.443us    (1.857ms ... 2.763ms)        2.08ms     2.763ms    2.763ms   
generate 100_000 ids   100      1.982s         19.826ms ± 761.926us  (18.681ms ... 22.972ms)      20.169ms   22.972ms   22.972ms  
generate 1_000_000 ids 5        986.937ms      197.387ms ± 1.897ms   (194.234ms ... 199.391ms)    197.787ms  199.391ms  199.391ms 
```

