defmodule UniqueID.Process do
  @moduledoc """
  Internal use in UniqueID
  """
  use GenServer

  def start_link(args), do: GenServer.start_link(__MODULE__, args, name: __MODULE__)
  def init(_), do: {:ok, %{}}

  def handle_call({:new_with_name, name, machine_id, timestamp_bits, seq_bits}, _from, state) do
    if ref = :persistent_term.get(name, nil) do
      {:reply, {:ok, ref}, state}
    else
      with {:ok, ref} <- UniqueID.new(machine_id, timestamp_bits, seq_bits) do
        :persistent_term.put(name, ref)
        {:reply, {:ok, ref}, state}
      else
        e ->
          {:reply, e, state}
      end
    end
  end
end
