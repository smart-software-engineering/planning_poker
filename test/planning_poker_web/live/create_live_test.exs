defmodule PlanningPokerWeb.CreateLiveTest do
  use PlanningPokerWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "CreateLive" do
    test "renders the create game form", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/new")

      assert html =~ "Create Planning Poker"
      assert html =~ "Game Title"
      assert html =~ "All users are moderators"  # The checkbox should be visible
      assert html =~ "Description (Markdown)"
      assert html =~ "Moderator Email"
      assert has_element?(view, "#create-game-form")

      # By default, all_moderators is true, so secret field should be hidden
      refute html =~ "Moderator Secret"
    end

    test "shows secret field when all_moderators is disabled", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/new")

      # Change all_moderators to false via form validation
      html = render_change(view, :validate, %{
        "poker" => %{"all_moderators" => "false"}
      })

      # Now secret field should be visible
      assert html =~ "Moderator Secret"
      assert has_element?(view, "input[name='poker[secret]']")
    end

    test "shows planning poker fibonacci sequence", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/new")

      assert html =~ "Planning Poker Fibonacci (1, 2, 3, 5, 8, 13, 20, 40, 100)"
    end

    test "validates secret requirements when all_moderators is false", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/new")

      # Submit form with invalid secret and all_moderators false
      game_params = %{
        "name" => "Test Game",
        "secret" => "tooshort",
        "moderator_email" => "test@example.com",
        "card_type" => "fibonacci",
        "all_moderators" => "false"
      }

      html = render_submit(view, :create, %{"poker" => game_params})

      assert html =~ "should be at least 16 character(s)"
      assert html =~ "must contain at least one uppercase letter"
      assert html =~ "must contain at least one number"
      assert html =~ "must contain at least one special character"
    end

    test "validates required fields", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/new")

      # Submit form with empty values to trigger validation
      html =
        render_submit(view, :create, %{
          "poker" => %{"name" => "", "moderator_email" => "", "all_moderators" => "true"}
        })

      assert html =~ "can&#39;t be blank"
    end

    test "creates a game with all_moderators enabled (default)", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/new")

      game_params = %{
        "name" => "Test All Moderators Game",
        "description" => "## Test Description",
        "moderator_email" => "test@example.com",
        "card_type" => "fibonacci",
        "all_moderators" => "true"
      }

      # Submit the form
      view
      |> form("#create-game-form", poker: game_params)
      |> render_submit()

      # Should redirect to game page
      _flash = assert_redirect(view)
    end

    test "creates a game with secret when all_moderators is disabled", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/new")

      # First change all_moderators to false to show secret field
      render_change(view, :validate, %{"poker" => %{"all_moderators" => "false"}})

      game_params = %{
        "name" => "Test Secret Game",
        "description" => "## Test Description",
        "secret" => "ValidTestSecret123!",
        "moderator_email" => "test@example.com",
        "card_type" => "fibonacci",
        "all_moderators" => "false"
      }

      # Submit the form
      view
      |> form("#create-game-form", poker: game_params)
      |> render_submit()

      # Should redirect to game page
      _flash = assert_redirect(view)
    end

    test "shows markdown preview on description change", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/new")

      # Update description field
      html =
        render_change(view, :validate, %{
          "poker" => %{"description" => "## Test Header\n\n- Item 1\n- Item 2"}
        })

      assert html =~ "Test Header"
      assert html =~ "Item 1"
      assert html =~ "Item 2"
    end
  end
end
