defmodule MastaniServer.Delivery.Delegate.Notifications do
  @moduledoc """
  The Delivery context.
  """
  alias MastaniServer.Accounts.User
  alias MastaniServer.Delivery.Notification
  alias Helper.ORM

  alias MastaniServer.Delivery.Delegate.Utils

  def notify_someone(%User{id: from_user_id}, %User{id: to_user_id}, info) do
    attrs = %{
      from_user_id: from_user_id,
      to_user_id: to_user_id,
      action: info.action,
      source_id: info.source_id,
      source_title: info.source_title,
      source_type: info.source_type,
      source_preview: info.source_preview
    }

    Notification |> ORM.create(attrs)
  end

  @doc """
  fetch notifications from Delivery
  """
  def fetch_notifications(%User{} = user, %{page: _, size: _, read: _} = filter) do
    Utils.fetch_messages(user, Notification, filter)
  end
end