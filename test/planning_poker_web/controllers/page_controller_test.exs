defmodule PlanningPokerWeb.PageControllerTest do
  use PlanningPokerWeb.ConnCase

  describe "home page" do
    test "renders home page with create button", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)

      assert response =~ "Create a planning poker"
    end

    test "renders join game form", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)

      assert response =~ "Join"
    end
  end

  describe "join action" do
    test "redirects to poker game with valid UUID", %{conn: conn} do
      valid_uuid = "550e8400-e29b-41d4-a716-446655440000"

      conn = post(conn, ~p"/join", %{"uuid" => valid_uuid})

      assert redirected_to(conn) == ~p"/poker/#{valid_uuid}"
    end

    test "redirects to home with error for invalid UUID format", %{conn: conn} do
      invalid_uuid = "not-a-valid-uuid"

      conn = post(conn, ~p"/join", %{"uuid" => invalid_uuid})

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Invalid game ID format"
    end

    test "redirects to home with error for empty UUID", %{conn: conn} do
      conn = post(conn, ~p"/join", %{"uuid" => ""})

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Game ID is required"
    end

    test "redirects to home with error when UUID is missing", %{conn: conn} do
      conn = post(conn, ~p"/join", %{})

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Game ID is required"
    end

    test "normalizes UUID to lowercase", %{conn: conn} do
      uppercase_uuid = "550E8400-E29B-41D4-A716-446655440000"
      expected_uuid = "550e8400-e29b-41d4-a716-446655440000"

      conn = post(conn, ~p"/join", %{"uuid" => uppercase_uuid})

      assert redirected_to(conn) == ~p"/poker/#{expected_uuid}"
    end

    test "trims whitespace from UUID", %{conn: conn} do
      uuid_with_spaces = "  550e8400-e29b-41d4-a716-446655440000  "
      expected_uuid = "550e8400-e29b-41d4-a716-446655440000"

      conn = post(conn, ~p"/join", %{"uuid" => uuid_with_spaces})

      assert redirected_to(conn) == ~p"/poker/#{expected_uuid}"
    end
  end
end
