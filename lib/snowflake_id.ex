defmodule SnowflakeId do
  @moduledoc """
  fast snowflake id generator
  """

  # default bits range
  # snowflake_id = | machine_id | timestamp | seq  |
  # (64)         = | (10)       | (42)      | (12) |

  import Bitwise

  # 2024-01-01 00:00:00 에 해당하는 unix_time(milliseconds)
  @epoch_shift :erlang.universaltime_to_posixtime({{2024, 1, 1}, {0, 0, 0}}) * 1000

  @uid_bits 64
  @machine_id_bits 10
  @timestamp_bits 42
  @seq_bits 12
  @uid_bits @machine_id_bits + @timestamp_bits + @seq_bits
  @max_machine_id_bits 40

  @type ref :: :atomics.atomics_ref()
  @type uid_value :: non_neg_integer()
  @type machine_id_value :: non_neg_integer()
  @type timestamp_value :: non_neg_integer()
  @type seq_value :: non_neg_integer()

  @spec init(machine_id_value(), non_neg_integer(), non_neg_integer(), non_neg_integer()) ::
          {:ok, ref()} | :error_invalid_bits | :error_exceed_machine_id_bits
  @spec init(non_neg_integer()) ::
          :error_exceed_machine_id_bits | :error_invalid_bits | {:ok, :atomics.atomics_ref()}
  def init(
        machine_id,
        machine_id_bits \\ @machine_id_bits,
        timestamp_bits \\ @timestamp_bits,
        seq_bits \\ @seq_bits
      ) do
    cond do
      machine_id_bits >= @max_machine_id_bits ->
        :error_exceed_machine_id_bits

      machine_id > (1 <<< machine_id_bits) - 1 ->
        :error_exceed_machine_id_bits

      machine_id_bits + timestamp_bits + seq_bits != @uid_bits ->
        :error_invalid_bits

      true ->
        ref = :atomics.new(2, signed: false)

        <<ts_n_seq::unsigned-integer-size(timestamp_bits + seq_bits)>> =
          <<now_timestamp()::unsigned-integer-size(timestamp_bits),
            0::unsigned-integer-size(seq_bits)>>

        :atomics.put(ref, 1, ts_n_seq)

        put_bits(ref, machine_id, machine_id_bits, timestamp_bits, seq_bits)

        {:ok, ref}
    end
  end

  @doc "next_id operation guarantee atomicity"
  @spec next_id(ref()) :: uid_value()
  def next_id(ref) do
    {machine_id, machine_id_bits, timestamp_bits, seq_bits} = get_bits(ref)

    timestamp_n_seq = next_timestamp_n_seq(ref, timestamp_bits, seq_bits)

    <<uid::unsigned-integer-size(@uid_bits)>> =
      <<machine_id::unsigned-integer-size(machine_id_bits),
        timestamp_n_seq::unsigned-integer-size(timestamp_bits + seq_bits)>>

    uid
  end

  @doc false
  @spec next_timestamp_n_seq(ref, non_neg_integer(), non_neg_integer()) :: non_neg_integer()
  defp next_timestamp_n_seq(ref, timestamp_bits, seq_bits) do
    old_id = :atomics.get(ref, 1)

    <<old_ts::unsigned-integer-size(timestamp_bits), old_seq::unsigned-integer-size(seq_bits)>> =
      <<old_id::unsigned-integer-size(timestamp_bits + seq_bits)>>

    new_ts = now_timestamp()

    new_seq =
      if new_ts != old_ts do
        0
      else
        old_seq + 1
      end

    <<new_id::unsigned-integer-size(timestamp_bits + seq_bits)>> =
      <<new_ts::unsigned-integer-size(timestamp_bits), new_seq::unsigned-integer-size(seq_bits)>>

    max_seq_value = (1 <<< seq_bits) - 1

    if old_seq == max_seq_value or
         :atomics.compare_exchange(ref, 1, old_id, new_id) != :ok do
      Process.sleep(1)
      next_timestamp_n_seq(ref, timestamp_bits, seq_bits)
    else
      new_id
    end
  end

  @doc false
  @spec now_timestamp() :: timestamp_value()
  defp now_timestamp() do
    System.system_time(:millisecond) - @epoch_shift
  end

  @spec extract_id(ref(), uid_value()) :: {machine_id_value(), timestamp_value(), seq_value()}
  def extract_id(ref, uid) do
    {machine_id, machine_id_bits, timestamp_bits, seq_bits} = get_bits(ref)

    <<^machine_id::unsigned-integer-size(machine_id_bits),
      timestamp::unsigned-integer-size(timestamp_bits),
      seq::unsigned-integer-size(seq_bits)>> = <<uid::unsigned-integer-size(@uid_bits)>>

    {machine_id, timestamp, seq}
  end

  @doc false
  @spec get_bits(ref()) ::
          {non_neg_integer(), non_neg_integer(), non_neg_integer(), non_neg_integer()}
  defp get_bits(ref) do
    bits = :atomics.get(ref, 2)

    <<machine_id::size(40), machine_id_bits::size(8), timestamp_bits::size(8), seq_bits::size(8)>> =
      <<bits::size(64)>>

    # machine_id = :atomics.get(ref, 2)
    # machine_id_bits = :atomics.get(ref, 3)
    # timestamp_bits = :atomics.get(ref, 4)
    # seq_bits = :atomics.get(ref, 5)
    {machine_id, machine_id_bits, timestamp_bits, seq_bits}
  end

  @doc false
  @spec put_bits(
          ref(),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer()
        ) :: :ok
  defp put_bits(ref, machine_id, machine_id_bits, timestamp_bits, seq_bits) do
    <<bits::size(64)>> =
      <<machine_id::size(40), machine_id_bits::size(8), timestamp_bits::size(8),
        seq_bits::size(8)>>

    :atomics.put(ref, 2, bits)
    # :atomics.put(ref, 2, machine_id)
    # :atomics.put(ref, 3, machine_id_bits)
    # :atomics.put(ref, 4, timestamp_bits)
    # :atomics.put(ref, 5, seq_bits)
    :ok
  end
end
