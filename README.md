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
