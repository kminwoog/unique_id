defmodule UniqueID do
  @moduledoc """
  A fast 64 bit unique id generator
  """

  # default bits range
  # id   = | sign | machine_id | timestamp | seq  |
  # (64) = | (1)  | (10)       | (41)      | (12) |

  use Supervisor
  import Bitwise

  @doc false
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc false
  def init(_) do
    Supervisor.init([UniqueID.Process], strategy: :one_for_one)
  end

  # unix_time(milliseconds) for 2024-01-01 00:00:00
  @epoch_shift :erlang.universaltime_to_posixtime({{2024, 1, 1}, {0, 0, 0}}) * 1000

  @uid_bits 64
  @sign_bits 1
  @machine_id_bits 10
  @timestamp_bits 41
  @seq_bits 12
  @uid_bits @sign_bits + @machine_id_bits + @timestamp_bits + @seq_bits
  @max_machine_id_bits 40

  @type ref :: :atomics.atomics_ref() | reference()
  @type uid_value :: non_neg_integer()
  @type machine_id_value :: non_neg_integer()
  @type timestamp_value :: non_neg_integer()
  @type seq_value :: non_neg_integer()
  @type name :: atom()

  @spec new_with_name(name(), machine_id_value(), non_neg_integer(), non_neg_integer()) ::
          {:ok, ref()} | :error_exceed_machine_id_bits | :error_overflow_machine_id
  def new_with_name(name, machine_id, timestamp_bits \\ @timestamp_bits, seq_bits \\ @seq_bits) do
    if ref = :persistent_term.get(name, nil) do
      {:ok, ref}
    else
      GenServer.call(
        UniqueID.Process,
        {:new_with_name, name, machine_id, timestamp_bits, seq_bits},
        :infinity
      )
    end
  end

  @spec new(machine_id_value(), non_neg_integer(), non_neg_integer()) ::
          {:ok, ref()} | :error_overflow_machine_id | :error_exceed_machine_id_bits
  def new(machine_id, timestamp_bits \\ @timestamp_bits, seq_bits \\ @seq_bits) do
    machine_id_bits = @uid_bits - (@sign_bits + timestamp_bits + seq_bits)

    cond do
      machine_id_bits <= 0 or machine_id_bits >= @max_machine_id_bits ->
        :error_exceed_machine_id_bits

      machine_id > (1 <<< machine_id_bits) - 1 ->
        :error_overflow_machine_id

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
  @spec next_id(ref() | name() | nil) :: uid_value()
  def next_id(ref) when is_reference(ref) do
    {machine_id, machine_id_bits, timestamp_bits, seq_bits} = get_bits(ref)

    timestamp_n_seq = next_timestamp_n_seq(ref, timestamp_bits, seq_bits)

    <<uid::unsigned-integer-size(@uid_bits)>> =
      <<0::unsigned-integer-size(@sign_bits), machine_id::unsigned-integer-size(machine_id_bits),
        timestamp_n_seq::unsigned-integer-size(timestamp_bits + seq_bits)>>

    uid
  end

  def next_id(nil), do: 0
  def next_id(name), do: next_id(get_ref(name))

  @doc false
  @spec next_timestamp_n_seq(ref(), non_neg_integer(), non_neg_integer()) :: non_neg_integer()
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

  @spec extract_id(ref() | name() | nil, uid_value()) ::
          {machine_id_value(), timestamp_value(), seq_value()}
  def extract_id(ref, uid) when is_reference(ref) do
    {machine_id, machine_id_bits, timestamp_bits, seq_bits} = get_bits(ref)

    <<_::unsigned-integer-size(@sign_bits), ^machine_id::unsigned-integer-size(machine_id_bits),
      timestamp::unsigned-integer-size(timestamp_bits),
      seq::unsigned-integer-size(seq_bits)>> = <<uid::unsigned-integer-size(@uid_bits)>>

    {machine_id, timestamp, seq}
  end

  def extract_id(nil, _uid), do: {0, 0, 0}
  def extract_id(name, uid), do: extract_id(get_ref(name), uid)

  @doc false
  @spec now_timestamp() :: timestamp_value()
  defp now_timestamp() do
    System.system_time(:millisecond) - @epoch_shift
  end

  @doc false
  @spec get_bits(ref()) ::
          {non_neg_integer(), non_neg_integer(), non_neg_integer(), non_neg_integer()}
  defp get_bits(ref) do
    bits = :atomics.get(ref, 2)

    <<machine_id::size(@max_machine_id_bits), machine_id_bits::size(8), timestamp_bits::size(8),
      seq_bits::size(8)>> = <<bits::size(64)>>

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
      <<machine_id::size(@max_machine_id_bits), machine_id_bits::size(8), timestamp_bits::size(8),
        seq_bits::size(8)>>

    :atomics.put(ref, 2, bits)
    :ok
  end

  @doc false
  @spec get_ref(name()) :: ref() | nil
  defp get_ref(name), do: :persistent_term.get(name, nil)
end
