defmodule PlanningPoker.PokerServerTest do
  @behaviour PlanningPoker.PokerServerBehaviour

  alias PlanningPoker.Poker

  @moduledoc """
  Test implementation of PokerServer that doesn't use GenServer processes.
  Used for testing to avoid database ownership and process isolation issues.
  """

  # Store poker states in ETS for test isolation
  @table_name :test_poker_states

  def find_or_start(poker_id) do
    # Ensure ETS table exists
    ensure_table_exists()

    case Poker.get_poker(poker_id) do
      nil ->
        {:error, :poker_not_found}

      poker ->
        # Store initial poker state
        poker_state = %{
          poker: poker,
          users: %{},
          created_at: DateTime.utc_now(),
          last_activity: DateTime.utc_now()
        }

        :ets.insert(@table_name, {poker_id, poker_state})
        :ok
    end
  end

  def get_poker_state(poker_id) do
    ensure_table_exists()

    case :ets.lookup(@table_name, poker_id) do
      [{^poker_id, state}] -> {:ok, state}
      [] -> {:error, :server_not_found}
    end
  end

  def add_user(poker_id, user_name) do
    ensure_table_exists()

    case :ets.lookup(@table_name, poker_id) do
      [{^poker_id, state}] ->
        updated_users =
          Map.put(state.users, user_name, %{
            name: user_name,
            joined_at: DateTime.utc_now()
          })

        updated_state = %{state | users: updated_users, last_activity: DateTime.utc_now()}
        :ets.insert(@table_name, {poker_id, updated_state})
        :ok

      [] ->
        {:error, :server_not_found}
    end
  end

  def remove_user(poker_id, user_name) do
    ensure_table_exists()

    case :ets.lookup(@table_name, poker_id) do
      [{^poker_id, state}] ->
        updated_users = Map.delete(state.users, user_name)
        updated_state = %{state | users: updated_users, last_activity: DateTime.utc_now()}
        :ets.insert(@table_name, {poker_id, updated_state})
        :ok

      [] ->
        {:error, :server_not_found}
    end
  end

  def get_users(poker_id) do
    case get_poker_state(poker_id) do
      {:ok, state} -> {:ok, state.users}
      error -> error
    end
  end

  # Helper function to ensure ETS table exists
  defp ensure_table_exists do
    case :ets.whereis(@table_name) do
      :undefined ->
        :ets.new(@table_name, [:named_table, :public, :set])

      _ ->
        :ok
    end
  end

  # Clean up function for tests
  def cleanup do
    case :ets.whereis(@table_name) do
      :undefined -> :ok
      _ -> :ets.delete(@table_name)
    end
  end
end
