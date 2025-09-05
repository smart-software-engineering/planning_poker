defmodule PlanningPoker.PokerFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PlanningPoker.Poker` context.
  """

  @doc """
  Generate a poker.
  """
  def poker_fixture(attrs \\ %{}) do
    {:ok, poker} =
      attrs
      |> Enum.into(%{
        name: "some name",
        card_type: "fibonacci"
      })
      |> PlanningPoker.Poker.create_poker()

    poker
  end
end
