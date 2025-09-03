defmodule PlanningPokerWeb.CreateLiveTest do
  use PlanningPokerWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "CreateLive" do
    test "renders the create poker form", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/new")

      assert html =~ "Create Planning Poker"
      assert html =~ "Poker Title"
      assert html =~ "Description (Markdown)"
      assert has_element?(view, "#create-poker-form")
    end

    test "shows planning poker fibonacci sequence", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/new")

      assert html =~ "Planning Poker Fibonacci (1, 2, 3, 5, 8, 13, 20, 40, 100)"
    end

    test "validates required fields", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/new")

      # First trigger validation by changing a field to empty
      html =
        render_change(view, :validate, %{
          "create_poker_form" => %{"name" => ""}
        })

      # Should show validation errors
      assert html =~ "can&#39;t be blank"
    end

    test "creates a poker successfully", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/new")

      game_params = %{
        "name" => "Test Poker",
        "description" => "## Test Description",
        "moderator_email" => "test@example.com",
        "card_type" => "fibonacci"
      }

      # Submit the form
      view
      |> form("#create-poker-form", create_poker_form: game_params)
      |> render_submit()

      # Should redirect to poker page
      _flash = assert_redirect(view)
    end

    test "shows markdown preview on description change", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/new")

      # Update description field
      html =
        render_change(view, :validate, %{
          "create_poker_form" => %{"description" => "## Test Header\n\n- Item 1\n- Item 2"}
        })

      assert html =~ "Test Header"
      assert html =~ "Item 1"
      assert html =~ "Item 2"
    end
  end
end
