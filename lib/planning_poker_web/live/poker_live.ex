defmodule PlanningPokerWeb.PokerLive do
  use PlanningPokerWeb, :live_view

  alias PlanningPoker.Poker
  alias PlanningPokerWeb.Forms.JoinPokerForm

  # Get the PokerServer implementation from config
  @poker_server Application.compile_env(:planning_poker, :poker_server)

  def mount(%{"id" => id}, _session, socket) do
    case Poker.get_poker(id) do
      nil ->
        {:ok, push_navigate(socket, to: ~p"/")}

      poker ->
        # Subscribe to poker updates (only for real PokerServer, not test)
        unless @poker_server == PlanningPoker.PokerServerTest do
          Phoenix.PubSub.subscribe(PlanningPoker.PubSub, "poker:#{id}")
        end

        # Find or start the PokerServer using injected implementation
        case @poker_server.find_or_start(id) do
          :ok ->
            {:ok,
             socket
             |> assign(:page_title, poker.name)
             |> assign(:poker_id, id)
             |> assign(:poker, poker)
             |> assign(:poker_url, url(~p"/poker/#{id}"))
             |> assign(:user_identified, false)
             |> assign(:user_name, nil)
             |> assign(:users, %{})
             |> assign(:poker_state, nil)
             |> assign(:form, to_form(JoinPokerForm.changeset(%JoinPokerForm{})))}

          {:error, reason} ->
            {:ok,
             socket
             |> put_flash(:error, "Failed to start poker session: #{inspect(reason)}")
             |> push_navigate(to: ~p"/")}
        end
    end
  end

  def handle_event("identify_user", %{"join_poker_form" => form_params}, socket) do
    %{poker_id: poker_id} = socket.assigns

    changeset = JoinPokerForm.changeset(%JoinPokerForm{}, form_params)

    if changeset.valid? do
      data = Ecto.Changeset.apply_changes(changeset)
      user_name = String.trim(data.name)

      handle_user_identification(socket, poker_id, user_name)
    else
      {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def terminate(_reason, socket) do
    # Remove user from PokerServer when LiveView terminates
    if socket.assigns[:user_identified] && socket.assigns[:user_name] do
      @poker_server.remove_user(socket.assigns.poker_id, socket.assigns.user_name)
    end

    :ok
  end

  # Handle PubSub messages
  def handle_info({:user_joined, user_name}, socket) do
    # Update users list when someone joins
    case @poker_server.get_users(socket.assigns.poker_id) do
      {:ok, users} ->
        {:noreply,
         socket
         |> assign(:users, users)
         |> put_flash(:info, "#{user_name} joined")}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_info({:user_left, user_name}, socket) do
    # Update users list when someone leaves
    case @poker_server.get_users(socket.assigns.poker_id) do
      {:ok, users} ->
        {:noreply,
         socket
         |> assign(:users, users)
         |> put_flash(:info, "#{user_name} left")}

      _ ->
        {:noreply, socket}
    end
  end

  # Private helper to handle user identification and reduce nesting
  defp handle_user_identification(socket, poker_id, user_name) do
    case @poker_server.add_user(poker_id, user_name) do
      :ok ->
        handle_successful_user_addition(socket, poker_id, user_name)

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to join poker: #{inspect(reason)}")}
    end
  end

  # Private helper to handle successful user addition
  defp handle_successful_user_addition(socket, poker_id, user_name) do
    case @poker_server.get_poker_state(poker_id) do
      {:ok, poker_state} ->
        welcome_message = "Welcome, #{user_name}!"

        {:noreply,
         socket
         |> assign(:user_identified, true)
         |> assign(:user_name, user_name)
         |> assign(:poker_state, poker_state)
         |> assign(:users, poker_state.users)
         |> put_flash(:info, welcome_message)}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to load poker state: #{inspect(reason)}")}
    end
  end
end
