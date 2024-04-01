# UniqueID

[![Hex.pm Version](http://img.shields.io/hexpm/v/unique_id.svg)](https://hex.pm/packages/unique_id) [![Hex Docs](https://img.shields.io/badge/hex-docs-brightgreen.svg)](https://hexdocs.pm/unique_id/)

UniqueID aims to provide atomicity even when called by multiple processes, while ensuring reasonably fast performance.

It is designed to be called without worrying about overload in performance-critical systems.

To achieve this, it utilizes erlang's atomics to ensure fast performance.

By default, UniqueID is an unsigned 64-bit integer and composed of

```elixir
  # unique_id = | machine_id | timestamp | seq  |
  # (64)      = | (10)       | (42)      | (12) |
```


## Note

In extreme scenarios where too many IDs are issued by multiple processes within 1 millisecond,

a Process.sleep(1) call is made to ensure atomicity. which may lead to a throughput degradation.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `unique_id` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:unique_id, "~> 1.1"}
  ]
end
```
then run as
```sh
$ mix deps.get
```

## Usage

To generate a unique id (aka UniqueID), you can call it as follows:

```elixir
iex> machine_id = 111
iex> {:ok, ref} = UniqueID.new(machine_id)
iex> UniqueID.next_id(ref)
```

To change bit range of UniqueID

```elixir
iex> machine_id = 111
iex> timestamp_bits = 43
iex> seq_bits = 11
iex> {:ok, ref} = UniqueID.new(machine_id, timestamp_bits, seq_bits)
iex> UniqueID.next_id(ref)
```

If use new_with_name/4, UniqueID intialized under its name,

which can then be used instead of the reference in subsequent operations

```elixir
iex> UniqueID.start_link([])
iex> machine_id = 111
iex> {:ok, _ref} = UniqueID.new_with_name(:uid_test_name, machine_id)
iex> UniqueID.next_id(:uid_test_name)
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
Estimated total run time: 21 s

Benchmarking UniqueID.next_id ...
Benchmarking UniqueID.next_id with name ...
Benchmarking UniqueID.extract_id ...
Calculating statistics...

Name                                 ips        average  deviation         median         99th %
UniqueID.extract_id               7.99 M      125.22 ns    ±34.17%      102.40 ns      204.80 ns
UniqueID.next_id                  2.63 M      380.82 ns    ±12.43%      409.60 ns      409.60 ns
UniqueID.next_id with name        2.50 M      400.38 ns     ±8.02%      409.60 ns      409.60 ns

Comparison:
UniqueID.extract_id               7.99 M
UniqueID.next_id                  2.63 M - 3.04x slower +255.60 ns
UniqueID.next_id with name        2.50 M - 3.20x slower +275.16 ns
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
Estimated total run time: 21 s

Benchmarking UniqueID.next_id ...
Benchmarking UniqueID.next_id with name ...
Benchmarking UniqueID.extract_id ...
Calculating statistics...

Name                                 ips        average  deviation         median         99th %
UniqueID.extract_id               6.87 M      145.67 ns    ±35.29%      102.40 ns      204.80 ns
UniqueID.next_id                  1.30 M      767.90 ns  ±2019.50%      409.60 ns     1934.34 ns
UniqueID.next_id with name        1.06 M      940.92 ns  ±2069.48%           0 ns       19456 ns

Comparison:
UniqueID.extract_id               6.87 M
UniqueID.next_id                  1.30 M - 5.27x slower +622.23 ns
UniqueID.next_id with name        1.06 M - 6.46x slower +795.26 ns
```
