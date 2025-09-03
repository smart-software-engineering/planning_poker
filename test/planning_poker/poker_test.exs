defmodule PlanningPoker.PokerTest do
  use PlanningPoker.DataCase

  alias PlanningPoker.Poker

  describe "poker" do
    alias PlanningPoker.Poker.Poker, as: SinglePoker

    import PlanningPoker.PokerFixtures

    @invalid_attrs %{name: nil, description: nil}

    test "get_poker/1 returns the poker with given id" do
      poker = poker_fixture()
      retrieved_poker = Poker.get_poker(poker.id)

      # Compare without associations for test consistency
      assert retrieved_poker.id == poker.id
      assert retrieved_poker.name == poker.name
      assert retrieved_poker.card_type == poker.card_type
      # Votings should be loaded as an empty list
      assert retrieved_poker.votings == []
    end

    test "create_poker/1 with valid data creates a poker" do
      valid_attrs = %{
        name: "some name",
        description: "some description"
      }

      assert {:ok, %SinglePoker{} = poker} = Poker.create_poker(valid_attrs)
      assert poker.name == "some name"
      assert poker.description == "some description"
    end

    test "create_poker/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Poker.create_poker(@invalid_attrs)
    end

    test "update_poker/2 with valid data updates the poker" do
      poker = poker_fixture()

      update_attrs = %{
        name: "some updated name",
        description: "some updated description"
      }

      assert {:ok, %SinglePoker{} = poker} = Poker.update_poker(poker, update_attrs)
      assert poker.name == "some updated name"
      assert poker.description == "some updated description"
    end

    test "update_poker/2 with invalid data returns error changeset" do
      poker = poker_fixture()
      assert {:error, %Ecto.Changeset{}} = Poker.update_poker(poker, @invalid_attrs)

      # Compare the reloaded poker with the original (both now have votings loaded)
      retrieved_poker = Poker.get_poker(poker.id)
      assert retrieved_poker.id == poker.id
      assert retrieved_poker.name == poker.name
    end

    test "end_poker/1 deletes the poker" do
      poker = poker_fixture()
      assert {:ok, %SinglePoker{}} = Poker.end_poker(poker)
      assert nil == Poker.get_poker(poker.id)
    end

    test "change_poker/1 returns a poker changeset" do
      poker = poker_fixture()
      assert %Ecto.Changeset{} = Poker.change_poker(poker)
    end
  end
end
