defmodule PlanningPoker.PokerServer do
  use GenServer
  require Logger

  @doc """
  Starts a PokerServer for the given poker session ID.
  This server is kept for future voting functionality but currently does nothing.
  """
  def start_link(poker_id) do
    GenServer.start_link(__MODULE__, poker_id, name: global_name(poker_id))
  end

  ## Server Callbacks

  @impl true
  def init(poker_id) do
    Logger.info("Starting PokerServer for poker #{poker_id} (placeholder for future voting)")
    {:ok, %{poker_id: poker_id}}
  end

  @impl true
  def terminate(reason, state) do
    Logger.info("PokerServer for poker #{state.poker_id} terminating: #{inspect(reason)}")
    :ok
  end

  ## Private Functions

  defp global_name(poker_id) do
    {:global, {:poker_server, poker_id}}
  end
end
