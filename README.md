# SnowflakeId

SnowflakeId aims to provide atomicity even when called by multiple processes, while ensuring reasonably fast performance.

It is designed to be called without worrying about overload in performance-critical systems.

To achieve this, it utilizes erlang's atomics to ensure fast performance.

By default, Snowflake ID is an unsigned 64-bit integer and has the following structure:

```elixir
  # snowflake_id = | machine_id | timestamp | seq  |
  # (64)         = | (10)       | (42)      | (12) |
```


## Note

In extreme scenarios where too many IDs are issued by multiple processes within 1 millisecond,

a Process.sleep(1) call is made to ensure atomicity. This can result in a degradation of throughput.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `snowflake_id` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:snowflake_id, "~> 1.0.0"}
  ]
end
```
then run as
```sh
$ mix deps.get
```

## Usage

To generate a SnowflakeId, you can call it as follows:

```elixir
iex> machine_id = 10
iex> {:ok, ref} = SnowflakeId.init(machine_id)
iex> SnowflakeId.next_id(ref)
iex> SnowflakeId.extract_id(ref, uid)
```

## Benchmarks

It performs faster when called by a single process than in a race condition with multiple processes.

### parallel: 1


```elixir
$ mix run bench/bench.exs
Operating System: Windows
CPU Information: AMD Ryzen 5 3600 6-Core Processor
Number of Available Cores: 12
Available memory: 15.93 GB
Elixir 1.14.2
Erlang 25.0
JIT enabled: true

Benchmark suite executing with the following configuration:
warmup: 2 s
time: 5 s
memory time: 0 ns
reduction time: 0 ns
parallel: 1
inputs: none specified
Estimated total run time: 35 s

Name                             ips        average  deviation         median         99th %
System.os_time               13.89 M       72.02 ns    ±65.13%      102.40 ns      102.40 ns
System.monotonic_time        10.34 M       96.68 ns    ±25.08%      102.40 ns      102.40 ns
System.system_time            9.91 M      100.91 ns    ±16.50%      102.40 ns      102.40 ns
SnowflakeId.extract_id        8.49 M      117.77 ns    ±31.17%      102.40 ns      204.80 ns
SnowflakeId.next_id           2.44 M      409.98 ns   ±122.80%           0 ns        1024 ns

Comparison:
System.os_time               13.89 M
System.monotonic_time        10.34 M - 1.34x slower +24.66 ns
System.system_time            9.91 M - 1.40x slower +28.89 ns
SnowflakeId.extract_id        8.49 M - 1.64x slower +45.75 ns
SnowflakeId.next_id           2.44 M - 5.69x slower +337.97 ns
```

### parallel: 2
```elixir
$ mix run bench/bench.exs
Operating System: Windows
CPU Information: AMD Ryzen 5 3600 6-Core Processor
Number of Available Cores: 12
Available memory: 15.93 GB
Elixir 1.14.2
Erlang 25.0
JIT enabled: true

Benchmark suite executing with the following configuration:
warmup: 2 s
time: 5 s
memory time: 0 ns
reduction time: 0 ns
parallel: 2
inputs: none specified
Estimated total run time: 35 s

Benchmarking SnowflakeId.next_id ...
Benchmarking SnowflakeId.extract_id ...
Benchmarking System.system_time ...
Benchmarking System.os_time ...
Benchmarking System.monotonic_time ...
Calculating statistics...

Name                             ips        average  deviation         median         99th %
System.os_time               13.88 M       72.02 ns    ±65.57%      102.40 ns      102.40 ns
System.monotonic_time        10.27 M       97.41 ns    ±25.87%      102.40 ns      102.40 ns
System.system_time            8.83 M      113.22 ns   ±270.02%           0 ns        1024 ns
SnowflakeId.extract_id        7.13 M      140.32 ns    ±42.92%      102.40 ns      204.80 ns
SnowflakeId.next_id           1.37 M      732.27 ns   ±364.74%           0 ns       19456 ns

Comparison:
System.os_time               13.88 M
System.monotonic_time        10.27 M - 1.35x slower +25.39 ns
System.system_time            8.83 M - 1.57x slower +41.20 ns
SnowflakeId.extract_id        7.13 M - 1.95x slower +68.30 ns
SnowflakeId.next_id           1.37 M - 10.17x slower +660.25 ns
```
