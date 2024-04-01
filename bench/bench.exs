
{:ok, ref} = UniqueID.new(1)

[parallel: 2, print: [fast_warning: false]]
|> Benchee.init()
|> Benchee.system()
|> Benchee.benchmark(
  "UniqueID.next_id", fn -> UniqueID.next_id(ref) end)
|> Benchee.benchmark(
  "UniqueID.extract_id", fn -> UniqueID.extract_id(ref, 18046409646354432) end)
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
