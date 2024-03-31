
{:ok, ref} = SnowflakeIdx.init(1)

[parallel: 1, print: [fast_warning: false]]
|> Benchee.init()
|> Benchee.system()
|> Benchee.benchmark(
  "SnowflakeIdx.next_id", fn -> SnowflakeIdx.next_id(ref) end)
|> Benchee.benchmark(
  "SnowflakeIdx.extract_id", fn -> SnowflakeIdx.extract_id(ref, 18046409646354432) end)
|> Benchee.benchmark(
  "System.system_time", fn -> System.system_time(:millisecond) end)
|> Benchee.benchmark(
  "System.os_time", fn -> System.os_time(:millisecond) end)
|> Benchee.benchmark(
  "System.monotonic_time", fn -> System.monotonic_time(:millisecond) end)
  |> Benchee.collect()
  |> Benchee.statistics()
  |> Benchee.relative_statistics()
  |> Benchee.Formatter.output(Benchee.Formatters.Console)
