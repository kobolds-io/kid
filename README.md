# KID

KID (kobolds-id) is heavily influenced by Twitter snowflake id. It uses a fairly simple structure to guarantee uniqness. It is stored as an unsigned 64 bit integer that makes use of the system clock, a node identifier and a counter. This library has **no production dependencies**.

| zig version | kid version |
|-------------|-------------|
| 0.15.x      | 0.0.3       |
| 0.16.0      | 0.1.0       |

## Usage

Using `kid` is just as simple as using any other `zig` dependency.

```zig
// import the library into your file
const kid = @import("kid");

fn main(init: std.process.Init) !void {
    // since kid uses clocks, we need to include a `std.Io`
    const io = init.io;
    // your code
    // ....

    // The id that will be appended to the end of the ID to uniquely identify the node
    const node_id: u11 = 432;
    kid.configure(node_id, .{});

    const id = kid.generate(io);

    // your code
    // ...
}
```

You can decode the ID for more detailed analysis or for log storage

```zig
    const node_id: u11 = 432;
    kid.configure(node_id, .{});

    const id = kid.generate(io);

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

Install using zig fetch

```bash
zig fetch --save  https://gitlab.com/kobolds-io/kid/-/archive/v0.1.0/kid-v0.1.0.tar.gz
```

Alternatively, you can install `kid` just like any other `zig` dependency by editing your `build.zig.zon` file.

```zig
    .dependencies = .{
        .kid = .{
            .url = "https://gitlab.com/kobolds-io/kid/-/archive/v0.1.0/kid-v0.1.0.tar.gz",
            .hash = "<hash>",
        },
    },
```

run `zig build --fetch` to fetch the dependencies. This will return an error as the has will not match. Copy the new hash and try again.Sometimes `zig` is helpful and it caches stuff for you in the `zig-cache` dir. Try deleting that directory if you see some issues.

In the `build.zig` file add the library as a dependency.

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
  Total Memory:     14.412GiB
--------------------------------------------------------

|----------------|
| KID Benchmarks |
|----------------|
benchmark                runs     total time     time/run (avg ± σ)    (min ... max)                p75        p99        p995      
-------------------------------------------------------------------------------------------------------------------------------------
generate 1 ids           100      3.976us        39ns ± 11ns           (37ns ... 151ns)             39ns       151ns      151ns      
generate 1000 ids        100      11.632ms       116.321us ± 250.21us  (24.782us ... 832.23us)      25.993us   832.23us   832.23us   
generate 8192 ids        100      99.949ms       999.497us ± 4.35us    (958.405us ... 1.004ms)      1ms        1.004ms    1.004ms    
generate 10_000 ids      100      121.969ms      1.219ms ± 333.054us   (553.758us ... 1.903ms)      1.243ms    1.903ms    1.903ms    
generate 100_000 ids     100      1.22s          12.2ms ± 317.531us    (12.002ms ... 12.838ms)      12.05ms    12.838ms   12.838ms   
generate 1_000_000 ids   5        611.719ms      122.343ms ± 815.925us (121.886ms ... 123.799ms)    122.036ms  123.799ms  123.799ms  

|--------------------|
| uuid.v7 Benchmarks |
|--------------------|
benchmark               runs     total time     time/run (avg ± σ)    (min ... max)                p75        p99        p995      
------------------------------------------------------------------------------------------------------------------------------------
uuid.v7 1 ids           100      6.355us        63ns ± 189ns          (40ns ... 1.933us)           42ns       1.933us    1.933us    
uuid.v7 1000 ids        100      3.227ms        32.279us ± 768ns      (31.408us ... 37.46us)       32.195us   37.46us    37.46us    
uuid.v7 8192 ids        100      26.375ms       263.753us ± 16.1us    (256.931us ... 377.435us)    264.247us  377.435us  377.435us  
uuid.v7 10_000 ids      100      32.969ms       329.697us ± 36.497us  (313.72us ... 584.505us)     324.476us  584.505us  584.505us  
uuid.v7 100_000 ids     100      323.685ms      3.236ms ± 69.664us    (3.151ms ... 3.639ms)        3.253ms    3.639ms    3.639ms    
uuid.v7 1_000_000 ids   5        163.708ms      32.741ms ± 1.138ms    (31.982ms ... 34.67ms)       32.888ms   34.67ms    34.67ms    

|--------------------|
| uuid.v4 Benchmarks |
|--------------------|
benchmark               runs     total time     time/run (avg ± σ)    (min ... max)                p75        p99        p995      
------------------------------------------------------------------------------------------------------------------------------------
uuid.v4 1 ids           100      4.538us        45ns ± 174ns          (24ns ... 1.765us)           26ns       1.765us    1.765us    
uuid.v4 1000 ids        100      1.494ms        14.947us ± 673ns      (14.534us ... 19.887us)      14.914us   19.887us   19.887us   
uuid.v4 8192 ids        100      13.046ms       130.464us ± 22.389us  (118.743us ... 258.209us)    127.073us  258.209us  258.209us  
uuid.v4 10_000 ids      100      15.238ms       152.383us ± 17.32us   (145.349us ... 292.572us)    151.754us  292.572us  292.572us  
uuid.v4 100_000 ids     100      150.949ms      1.509ms ± 59.983us    (1.449ms ... 1.898ms)        1.524ms    1.898ms    1.898ms    
uuid.v4 1_000_000 ids   5        76.25ms        15.25ms ± 182.232us   (15.021ms ... 15.495ms)      15.329ms   15.495ms   15.495ms 
```
