defmodule PlanningPoker.Poker do
  @moduledoc """
  The Poker context.
  """
  import Ecto.Query, warn: false
  alias PlanningPoker.Repo

  alias PlanningPoker.Poker.Poker

  @doc """
  Gets a single poker with all associations loaded.

    ## Examples

      iex> get_poker("uuid")
      %Poker{votings: [...]}  # with votings preloaded

      iex> get_poker("unknown")
      nil

  """
  def get_poker(uuid) do
    case Repo.get(Poker, uuid) do
      nil -> nil
      poker -> Repo.preload(poker, :votings)
    end
  end

  @doc """
  Creates a new poker.

  ## Examples

      iex> create_poker(%{field: value})
      {:ok, %Poker{}}

      iex> create_poker(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_poker(attrs) do
    %Poker{}
    |> Poker.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a poker.

  ## Examples

      iex> update_poker(poker, %{field: new_value})
      {:ok, %Poker{}}

      iex> update_poker(poker, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_poker(%Poker{} = poker, attrs) do
    poker
    |> Poker.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Ends a poker by sending also an email about the poker to the moderator with all information including
  the voting rounds.

  ## Examples

      iex> end_poker(poker)
      {:ok, %Poker{}}

      iex> end_poker(poker)
      {:error, %Ecto.Changeset{}}

  """
  def end_poker(%Poker{} = poker) do
    # TODO send email with all information to moderator email
    Repo.delete(poker)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking poker changes.

  ## Examples

      iex> change_poker(poker)
      %Ecto.Changeset{data: %Poker{}}

  """
  def change_poker(%Poker{} = poker, attrs \\ %{}) do
    Poker.changeset(poker, attrs)
  end
end
