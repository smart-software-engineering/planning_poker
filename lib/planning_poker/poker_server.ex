defmodule PlanningPoker.PokerServer do
  @behaviour PlanningPoker.PokerServerBehaviour
  use GenServer
  require Logger

  alias PlanningPoker.Poker

  ## Client API

  @doc """
  Starts a PokerServer for the given poker session ID.
  Returns {:ok, pid} if started successfully, {:error, reason} otherwise.
  """
  def start_link(poker_id) do
    case Poker.get_poker(poker_id) do
      nil ->
        {:error, :poker_not_found}

      _poker ->
        GenServer.start_link(__MODULE__, poker_id, name: global_name(poker_id))
    end
  end

  @doc """
  Gets the current poker state from the PokerServer.
  """
  @impl true
  def get_poker_state(poker_id) do
    case :global.whereis_name(global_key(poker_id)) do
      :undefined ->
        {:error, :server_not_found}

      pid ->
        GenServer.call(pid, :get_poker_state)
    end
  end

  @doc """
  Adds a user to the poker session.
  """
  @impl true
  def add_user(poker_id, user_name) do
    case :global.whereis_name(global_key(poker_id)) do
      :undefined ->
        {:error, :server_not_found}

      pid ->
        GenServer.call(pid, {:add_user, user_name})
    end
  end

  @doc """
  Removes a user from the poker session.
  """
  @impl true
  def remove_user(poker_id, user_name) do
    case :global.whereis_name(global_key(poker_id)) do
      :undefined ->
        {:error, :server_not_found}

      pid ->
        GenServer.call(pid, {:remove_user, user_name})
    end
  end

  @doc """
  Gets all active users in the poker session.
  """
  @impl true
  def get_users(poker_id) do
    case :global.whereis_name(global_key(poker_id)) do
      :undefined ->
        {:error, :server_not_found}

      pid ->
        GenServer.call(pid, :get_users)
    end
  end

  @doc """
  Finds or starts a PokerServer for the given poker ID.
  """
  @impl true
  def find_or_start(poker_id) do
    case :global.whereis_name(global_key(poker_id)) do
      :undefined ->
        # Try to start the server via the supervisor
        case PlanningPoker.PokerSupervisor.start_poker(poker_id) do
          {:ok, _pid} -> :ok
          {:error, {:already_started, _pid}} -> :ok
          {:error, reason} -> {:error, reason}
        end

      _pid ->
        :ok
    end
  end

  ## Server Callbacks

  @impl true
  def init(poker_id) do
    Logger.info("Starting PokerServer for poker #{poker_id}")

    case load_poker_from_database(poker_id) do
      {:ok, poker_state} ->
        {:ok, poker_state}

      {:error, reason} ->
        Logger.error("Failed to load poker #{poker_id}: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  @impl true
  def handle_call(:get_poker_state, _from, state) do
    {:reply, {:ok, state}, state}
  end

  @impl true
  def handle_call({:add_user, user_name}, _from, state) do
    updated_users =
      Map.put(state.users, user_name, %{
        name: user_name,
        joined_at: DateTime.utc_now()
      })

    updated_state = %{state | users: updated_users}

    Logger.info("User #{user_name} joined poker #{state.poker.id}")

    # Broadcast user joined event to all LiveViews
    broadcast_update(state.poker.id, {:user_joined, user_name})

    {:reply, :ok, updated_state}
  end

  @impl true
  def handle_call({:remove_user, user_name}, _from, state) do
    updated_users = Map.delete(state.users, user_name)
    updated_state = %{state | users: updated_users}

    Logger.info("User #{user_name} left poker #{state.poker.id}")

    # Broadcast user left event to all LiveViews
    broadcast_update(state.poker.id, {:user_left, user_name})

    {:reply, :ok, updated_state}
  end

  @impl true
  def handle_call(:get_users, _from, state) do
    {:reply, {:ok, state.users}, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.info("PokerServer for poker #{state.poker.id} terminating: #{inspect(reason)}")
    :ok
  end

  ## Private Functions

  defp load_poker_from_database(poker_id) do
    case Poker.get_poker(poker_id) do
      nil ->
        {:error, :poker_not_found}

      poker ->
        # poker already has votings preloaded from context
        poker_state = %{
          poker: poker,
          users: %{},
          created_at: DateTime.utc_now(),
          last_activity: DateTime.utc_now()
        }

        {:ok, poker_state}
    end
  end

  defp global_name(poker_id) do
    {:global, global_key(poker_id)}
  end

  defp global_key(poker_id) do
    {:poker_server, poker_id}
  end

  defp broadcast_update(poker_id, message) do
    Phoenix.PubSub.broadcast(
      PlanningPoker.PubSub,
      "poker:#{poker_id}",
      message
    )
  end
end
