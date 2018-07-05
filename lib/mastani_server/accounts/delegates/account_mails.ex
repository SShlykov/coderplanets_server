defmodule MastaniServer.Accounts.Delegate.AccountMails do
  import Ecto.Query, warn: false
  import Helper.Utils, only: [done: 1]
  import ShortMaps

  alias MastaniServer.Repo
  alias MastaniServer.Accounts.{User, MentionMail, NotificationMail}
  alias MastaniServer.Delivery
  alias Helper.ORM

  def mailbox_status(%User{} = user), do: Delivery.mailbox_status(user)

  def fetch_mentions(%User{} = user, filter) do
    with {:ok, mentions} <- Delivery.fetch_mentions(user, filter),
         {:ok, washed_mentions} <- wash_data(MentionMail, mentions.entries) do
      MentionMail |> messages_handler(washed_mentions, user, filter)
    end
  end

  def fetch_notifications(%User{} = user, filter) do
    with {:ok, notifications} <- Delivery.fetch_notifications(user, filter),
         {:ok, washed_notifications} <- wash_data(NotificationMail, notifications.entries) do
      NotificationMail |> messages_handler(washed_notifications, user, filter)
    end
  end

  defp messages_handler(
         queryable,
         washed_data,
         %User{id: user_id},
         %{page: page, size: size, read: read} = filter
       ) do
    queryable
    |> Repo.insert_all(washed_data)

    queryable
    |> where([m], m.to_user_id == ^user_id)
    |> where([m], m.read == ^read)
    |> ORM.paginater(~m(page size)a)
    |> done()
  end

  def mark_mail_read(%MentionMail{id: id}, %User{} = user) do
    do_mark_mail_read(MentionMail, id, user)
  end

  def mark_mail_read(%NotificationMail{id: id}, %User{} = user) do
    do_mark_mail_read(NotificationMail, id, user)
  end

  def mark_mail_read_all(%User{} = user, :mention) do
    user |> do_mark_mail_read_all(MentionMail, :mention)
  end

  def mark_mail_read_all(%User{} = user, :notification) do
    user |> do_mark_mail_read_all(NotificationMail, :notification)
  end

  defp do_mark_mail_read(queryable, id, %User{} = user) do
    with {:ok, mail} <- queryable |> ORM.find_by(id: id, to_user_id: user.id) do
      mail |> ORM.update(%{read: true})
    end
  end

  defp do_mark_mail_read_all(%User{} = user, mail, atom) do
    query =
      mail
      |> where([m], m.to_user_id == ^user.id)

    Repo.update_all(query, set: [read: true])

    Delivery.mark_read_all(user, atom)
  end

  defp wash_data(MentionMail, []), do: {:ok, []}
  defp wash_data(NotificationMail, []), do: {:ok, []}

  defp wash_data(MentionMail, list), do: do_wash_data(list)
  defp wash_data(NotificationMail, list), do: do_wash_data(list)

  defp do_wash_data(list) do
    convert =
      list
      |> Enum.map(
        &(Map.from_struct(&1)
          |> Map.delete(:__meta__)
          |> Map.delete(:id)
          |> Map.delete(:from_user)
          |> Map.delete(:to_user))
      )

    {:ok, convert}
  end
end