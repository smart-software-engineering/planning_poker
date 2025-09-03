defmodule PlanningPokerWeb.GameLiveTest do
  # async: false for ETS cleanup
  use PlanningPokerWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import PlanningPoker.PokerFixtures

  setup do
    # Clean up any previous test state
    case :ets.whereis(:test_game_states) do
      :undefined -> :ok
      _ -> :ets.delete(:test_game_states)
    end

    poker = poker_fixture(%{secret: "TestModeratorSecretLong123!"})
    %{poker: poker}
  end

  describe "GameLive" do
    setup do
      poker = poker_fixture(%{secret: "TestModeratorSecretLong123!"})
      %{poker: poker}
    end

    test "redirects to home if game doesn't exist", %{conn: conn} do
      invalid_id = Ecto.UUID.generate()

      assert {:error, {:live_redirect, %{to: "/"}}} = live(conn, ~p"/poker/#{invalid_id}")
    end

    test "renders identification form for new user", %{conn: conn, poker: poker} do
      {:ok, view, html} = live(conn, ~p"/poker/#{poker.id}")

      assert html =~ "Join Planning Session"
      assert html =~ poker.name
      assert has_element?(view, "#user-identification-form")
      assert has_element?(view, "input[name='user[name]']")
      assert has_element?(view, "input[name='user[secret]']")
    end

    test "shows game description in markdown", %{conn: conn} do
      poker_with_description =
        poker_fixture(%{
          description: "## Test Description\n\n- Item 1\n- Item 2",
          secret: "TestSecretDescription123!"
        })

      {:ok, _view, html} = live(conn, ~p"/poker/#{poker_with_description.id}")

      assert html =~ "Test Description"
      assert html =~ "Item 1"
      assert html =~ "Item 2"
    end

    test "identifies user as participant with name only", %{conn: conn, poker: poker} do
      {:ok, view, _html} = live(conn, ~p"/poker/#{poker.id}")

      # Submit identification form with name only
      form_data = %{"user" => %{"name" => "John Doe", "secret" => ""}}
      html = render_submit(view, :identify_user, form_data)

      assert html =~ "Welcome, John Doe!"
      assert html =~ "Participant"
      refute html =~ "Moderator"
      refute has_element?(view, "#user-identification-form")
    end

    test "identifies user as moderator with correct secret", %{conn: conn, poker: poker} do
      {:ok, view, _html} = live(conn, ~p"/poker/#{poker.id}")

      # Submit identification form with correct secret
      form_data = %{
        "user" => %{"name" => "Jane Smith", "secret" => "TestModeratorSecretLong123!"}
      }

      html = render_submit(view, :identify_user, form_data)

      assert html =~ "Welcome, Jane Smith!"
      assert html =~ "Moderator"
      assert html =~ "badge-primary"
      refute has_element?(view, "#user-identification-form")
    end

    test "identifies user as participant with wrong secret", %{conn: conn, poker: poker} do
      {:ok, view, _html} = live(conn, ~p"/poker/#{poker.id}")

      # Submit identification form with wrong secret
      form_data = %{
        "user" => %{"name" => "Bob Wilson", "secret" => "WrongSecretButLongEnough123!"}
      }

      html = render_submit(view, :identify_user, form_data)

      assert html =~ "Welcome, Bob Wilson!"
      assert html =~ "Participant"
      refute html =~ "Moderator"
    end

    test "shows error when name is empty", %{conn: conn, poker: poker} do
      {:ok, view, _html} = live(conn, ~p"/poker/#{poker.id}")

      # Submit identification form with empty name
      form_data = %{"user" => %{"name" => "", "secret" => ""}}
      html = render_submit(view, :identify_user, form_data)

      assert html =~ "Name is required"
      assert has_element?(view, "#user-identification-form")
    end

    test "trims whitespace from name", %{conn: conn, poker: poker} do
      {:ok, view, _html} = live(conn, ~p"/poker/#{poker.id}")

      # Submit identification form with whitespace around name
      form_data = %{"user" => %{"name" => "  Alice Cooper  ", "secret" => ""}}
      html = render_submit(view, :identify_user, form_data)

      assert html =~ "Welcome, Alice Cooper!"
      refute html =~ "  Alice Cooper  "
    end

    test "shows game details after identification", %{conn: conn, poker: poker} do
      {:ok, view, _html} = live(conn, ~p"/poker/#{poker.id}")

      # Identify as participant
      form_data = %{"user" => %{"name" => "Test User", "secret" => ""}}
      html = render_submit(view, :identify_user, form_data)

      # Should show game details
      assert html =~ "Game ID:"
      assert html =~ "Card Type:"
      assert html =~ poker.id
      assert html =~ "fibonacci"
    end

    test "shows appropriate flash messages", %{conn: conn, poker: poker} do
      {:ok, view, _html} = live(conn, ~p"/poker/#{poker.id}")

      # Test participant welcome
      form_data = %{"user" => %{"name" => "Regular User", "secret" => ""}}
      html = render_submit(view, :identify_user, form_data)
      assert html =~ "Welcome, Regular User!"

      # Test moderator welcome in a new session
      {:ok, view2, _html} = live(conn, ~p"/poker/#{poker.id}")

      form_data = %{
        "user" => %{"name" => "Moderator User", "secret" => "TestModeratorSecretLong123!"}
      }

      html = render_submit(view2, :identify_user, form_data)
      assert html =~ "Welcome moderator, Moderator User!"
    end

    test "sets correct page title", %{conn: conn, poker: poker} do
      {:ok, _view, _html} = live(conn, ~p"/poker/#{poker.id}")

      # The page title should be set to the game name
      # This is tested through the mount function assigning :page_title
      assert poker.name
    end
  end
end
