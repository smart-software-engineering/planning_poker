defmodule PlanningPoker.PokerTest do
  use PlanningPoker.DataCase

  alias PlanningPoker.Poker

  describe "poker" do
    alias PlanningPoker.Poker.Poker, as: SinglePoker

    import PlanningPoker.PokerFixtures

    @invalid_attrs %{name: nil, description: nil, moderator_email: nil, secret: nil}

    test "get_poker/1 returns the poker with given id" do
      poker = poker_fixture()
      retrieved_poker = Poker.get_poker(poker.id)

      # Compare without associations for test consistency
      assert retrieved_poker.id == poker.id
      assert retrieved_poker.name == poker.name
      assert retrieved_poker.secret == poker.secret
      assert retrieved_poker.moderator_email == poker.moderator_email
      assert retrieved_poker.card_type == poker.card_type
      # Votings should be loaded as an empty list
      assert retrieved_poker.votings == []
    end

    test "create_poker/1 with valid data creates a poker" do
      valid_attrs = %{
        name: "some name",
        description: "some description",
        moderator_email: "test@sample.xyz",
        secret: "ValidSecretTest123!"
      }

      assert {:ok, %SinglePoker{} = poker} = Poker.create_poker(valid_attrs)
      assert poker.name == "some name"
      assert poker.description == "some description"
      assert poker.moderator_email == "test@sample.xyz"
      assert poker.secret == "ValidSecretTest123!"
    end

    test "create_poker/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Poker.create_poker(@invalid_attrs)
    end

    test "update_poker/2 with valid data updates the poker" do
      poker = poker_fixture()

      update_attrs = %{
        name: "some updated name",
        description: "some updated description",
        moderator_email: "test2@example.xyz",
        secret: "UpdatedSecret456@"
      }

      assert {:ok, %SinglePoker{} = poker} = Poker.update_poker(poker, update_attrs)
      assert poker.name == "some updated name"
      assert poker.description == "some updated description"
      assert poker.moderator_email == "test2@example.xyz"
      assert poker.secret == "UpdatedSecret456@"
    end

    test "update_poker/2 with invalid data returns error changeset" do
      poker = poker_fixture()
      assert {:error, %Ecto.Changeset{}} = Poker.update_poker(poker, @invalid_attrs)

      # Compare the reloaded poker with the original (both now have votings loaded)
      retrieved_poker = Poker.get_poker(poker.id)
      assert retrieved_poker.id == poker.id
      assert retrieved_poker.name == poker.name
      assert retrieved_poker.secret == poker.secret
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

  describe "secret validation" do
    test "secret must be at least 16 characters" do
      attrs = %{name: "Test", all_moderators: false, secret: "Short1!", moderator_email: "test@example.com"}
      {:error, changeset} = Poker.create_poker(attrs)
      assert "should be at least 16 character(s)" in errors_on(changeset).secret
    end

    test "secret must not exceed 100 characters" do
      long_secret = String.duplicate("a", 96) <> "A123!"
      attrs = %{name: "Test", all_moderators: false, secret: long_secret, moderator_email: "test@example.com"}
      {:error, changeset} = Poker.create_poker(attrs)
      assert "should be at most 100 character(s)" in errors_on(changeset).secret
    end

    test "secret must contain at least one lowercase letter" do
      attrs = %{name: "Test", all_moderators: false, secret: "NOLOWERCASE123!", moderator_email: "test@example.com"}
      {:error, changeset} = Poker.create_poker(attrs)
      assert "must contain at least one lowercase letter" in errors_on(changeset).secret
    end

    test "secret must contain at least one uppercase letter" do
      attrs = %{name: "Test", all_moderators: false, secret: "nouppercase123!", moderator_email: "test@example.com"}
      {:error, changeset} = Poker.create_poker(attrs)
      assert "must contain at least one uppercase letter" in errors_on(changeset).secret
    end

    test "secret must contain at least one number" do
      attrs = %{name: "Test", all_moderators: false, secret: "NoNumbersHere!", moderator_email: "test@example.com"}
      {:error, changeset} = Poker.create_poker(attrs)
      assert "must contain at least one number" in errors_on(changeset).secret
    end

    test "secret must contain at least one special character" do
      attrs = %{name: "Test", all_moderators: false, secret: "NoSpecialChars123", moderator_email: "test@example.com"}
      {:error, changeset} = Poker.create_poker(attrs)

      assert "must contain at least one special character (!@#$%^&*-_+=)" in errors_on(changeset).secret
    end

    test "secret must only contain allowed characters" do
      attrs = %{name: "Test", all_moderators: false, secret: "InvalidChars123<>?", moderator_email: "test@example.com"}
      {:error, changeset} = Poker.create_poker(attrs)

      assert "contains invalid characters. Only letters, numbers, and !@#$%^&*-_+= are allowed" in errors_on(
               changeset
             ).secret
    end

    test "secret with all requirements is valid" do
      attrs = %{
        name: "Test",
        secret: "ValidPasswordTest123!",
        moderator_email: "test@example.com"
      }

      assert {:ok, poker} = Poker.create_poker(attrs)
      assert poker.secret == "ValidPasswordTest123!"
    end
  end
end
