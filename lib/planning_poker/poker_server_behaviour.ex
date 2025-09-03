defmodule PlanningPoker.PokerServerBehaviour do
  @moduledoc """
  Behaviour for PokerServer implementations.
  Allows for dependency injection and testing without environment checks.
  """

  @doc """
  Finds or starts a PokerServer for the given poker ID.
  """
  @callback find_or_start(poker_id :: binary()) :: :ok | {:error, term()}

  @doc """
  Gets the current poker state from the PokerServer.
  """
  @callback get_poker_state(poker_id :: binary()) :: {:ok, map()} | {:error, term()}

  @doc """
  Adds a user to the poker session.
  """
  @callback add_user(poker_id :: binary(), user_name :: binary()) ::
              :ok | {:error, term()}

  @doc """
  Removes a user from the poker session.
  """
  @callback remove_user(poker_id :: binary(), user_name :: binary()) ::
              :ok | {:error, term()}

  @doc """
  Gets all active users in the poker session.
  """
  @callback get_users(poker_id :: binary()) :: {:ok, map()} | {:error, term()}
end
