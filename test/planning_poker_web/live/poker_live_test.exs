defmodule PlanningPokerWeb.PokerLiveTest do
  use PlanningPokerWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import PlanningPoker.PokerFixtures

  describe "PokerLive" do
    setup do
      poker = poker_fixture()
      %{poker: poker}
    end

    test "renders poker page with join form", %{conn: conn, poker: poker} do
      {:ok, view, html} = live(conn, ~p"/poker/#{poker.id}")

      assert html =~ poker.name
      assert html =~ "Join Planning Session"
      assert has_element?(view, "#user-identification-form")
      assert has_element?(view, "input[type='text'][placeholder='Enter your name']")
      assert has_element?(view, "input[type='checkbox']")
      assert html =~ "data privacy policy"
    end

    test "requires privacy agreement to join", %{conn: conn, poker: poker} do
      {:ok, view, _html} = live(conn, ~p"/poker/#{poker.id}")

      # Try to submit with name but without privacy agreement
      view
      |> form("#user-identification-form",
        join_poker_form: %{"name" => "Test User", "privacy_agreement" => "false"}
      )
      |> render_submit()

      # Should still be on the join form (not joined)
      html = render(view)
      assert html =~ "Join Planning Session"
      refute html =~ "Welcome, Test User!"
    end

    test "allows joining with name and privacy agreement", %{conn: conn, poker: poker} do
      {:ok, view, _html} = live(conn, ~p"/poker/#{poker.id}")

      # Submit with both name and privacy agreement
      view
      |> form("#user-identification-form",
        join_poker_form: %{
          "name" => "Test User",
          "privacy_agreement" => "true"
        }
      )
      |> render_submit()

      # Should join successfully and show welcome message
      html = render(view)
      assert html =~ "Welcome, Test User!"
      assert html =~ "Active Users (1)"
      refute html =~ "Join Planning Session"
    end

    test "validates required name field", %{conn: conn, poker: poker} do
      {:ok, view, _html} = live(conn, ~p"/poker/#{poker.id}")

      # Try to submit with privacy agreement but no name
      view
      |> form("#user-identification-form",
        join_poker_form: %{
          "name" => "",
          "privacy_agreement" => "true"
        }
      )
      |> render_submit()

      # Should still be on the join form (not joined)
      html = render(view)
      assert html =~ "Join Planning Session"
      refute html =~ "Welcome,"
    end

    test "validates both name and privacy agreement are required", %{conn: conn, poker: poker} do
      {:ok, view, _html} = live(conn, ~p"/poker/#{poker.id}")

      # Try to submit with empty form
      view
      |> form("#user-identification-form",
        join_poker_form: %{
          "name" => "",
          "privacy_agreement" => "false"
        }
      )
      |> render_submit()

      # Should still be on the join form (not joined)
      html = render(view)
      assert html =~ "Join Planning Session"
      refute html =~ "Welcome,"
    end

    test "redirects to create mode when poker does not exist", %{conn: conn} do
      # Use a valid UUID format
      nonexistent_uuid = "00000000-0000-0000-0000-000000000000"

      # Should redirect to create mode during mount
      result = live(conn, ~p"/poker/#{nonexistent_uuid}")
      assert {:error, {:live_redirect, %{to: "/poker", flash: %{}}}} = result
    end
  end

  describe "authenticated user functionality" do
    setup do
      poker = poker_fixture()
      %{poker: poker}
    end

    defp join_session(view, name \\ "Test User") do
      view
      |> form("#user-identification-form",
        join_poker_form: %{
          "name" => name,
          "privacy_agreement" => "true"
        }
      )
      |> render_submit()
    end

    test "shows two-column layout after joining", %{conn: conn, poker: poker} do
      {:ok, view, _html} = live(conn, ~p"/poker/#{poker.id}")
      join_session(view)

      html = render(view)
      assert html =~ "Real-time poker functionality"
      assert html =~ "FIBONACCI"  # Card type badge
      assert html =~ "Close"
      assert html =~ "Leave"
      assert html =~ "Active Users (1)"
      assert html =~ "Test User (You)"
      assert html =~ "Share"
    end

    @tag :skip
    test "toggle_mute changes mute status and updates UI", %{conn: conn, poker: poker} do
      {:ok, view, _html} = live(conn, ~p"/poker/#{poker.id}")
      join_session(view)

      assert has_element?(view, "button[title='Mute']")
      refute has_element?(view, "button[title='Unmute']")

      view |> element("button[phx-click='toggle_mute']") |> render_click()
      
      # FIXME: Remove Process.sleep - technical debt for async PubSub message processing
      Process.sleep(50)
      assert has_element?(view, "button[title='Unmute']")
      refute has_element?(view, "button[title='Mute']")
      assert render(view) =~ "You are now muted"

      view |> element("button[phx-click='toggle_mute']") |> render_click()
      
      # FIXME: Remove Process.sleep - technical debt for async PubSub message processing
      Process.sleep(50)
      html = render(view)
      assert has_element?(view, "button[title='Mute']")
      refute has_element?(view, "button[title='Unmute']")
      assert html =~ "You are now unmuted"
    end

    test "toggle_session_state changes session status", %{conn: conn, poker: poker} do
      {:ok, view, _html} = live(conn, ~p"/poker/#{poker.id}")
      join_session(view)

      assert has_element?(view, "button", "Close")
      refute has_element?(view, "button", "Reopen")

      view |> element("button[phx-click='toggle_session_state']") |> render_click()

      assert has_element?(view, "button", "Reopen")
      refute has_element?(view, "button", "Close")
      assert render(view) =~ "Session closed successfully!"

      view |> element("button[phx-click='toggle_session_state']") |> render_click()

      html = render(view)
      assert has_element?(view, "button", "Close")
      refute has_element?(view, "button", "Reopen")
      assert html =~ "Session reopened successfully!"
    end

    test "leave_session navigates back to home", %{conn: conn, poker: poker} do
      {:ok, view, _html} = live(conn, ~p"/poker/#{poker.id}")
      join_session(view)

      html = render(view)
      assert html =~ "Test User (You)"

      view |> element("button[phx-click='leave_session']") |> render_click()

      assert_redirect(view, "/")
    end

    @tag :skip
    test "user list shows correct mute status styling", %{conn: conn, poker: poker} do
      {:ok, view, _html} = live(conn, ~p"/poker/#{poker.id}")
      join_session(view)

      html = render(view)
      refute html =~ "bg-red-400"

      view |> element("button[phx-click='toggle_mute']") |> render_click()
      
      # FIXME: Remove Process.sleep - technical debt for async PubSub message processing
      Process.sleep(50)

      html = render(view)
      assert html =~ "bg-red-400"
    end

    test "shows card type badge", %{conn: conn, poker: poker} do
      {:ok, view, _html} = live(conn, ~p"/poker/#{poker.id}")
      join_session(view)

      html = render(view)
      assert html =~ "FIBONACCI"  # Badge text in sidebar
    end

    test "current user appears first with highlighted background", %{conn: conn, poker: poker} do
      {:ok, view, _html} = live(conn, ~p"/poker/#{poker.id}")
      join_session(view)

      html = render(view)
      # Should have primary background for current user
      assert html =~ "bg-primary text-primary-content"  
      assert html =~ "Test User (You)"
    end

    test "copy URL functionality is present", %{conn: conn, poker: poker} do
      {:ok, view, _html} = live(conn, ~p"/poker/#{poker.id}")
      join_session(view)

      # Check that share section exists with copy functionality
      assert has_element?(view, "#copy-poker-url")
      assert has_element?(view, "input[readonly]")  # URL input field
      assert has_element?(view, "button[title='Copy URL']")
    end
  end
end
