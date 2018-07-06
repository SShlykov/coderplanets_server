defmodule MastaniServer.Test.Query.AccountsMessagesTest do
  use MastaniServer.TestTools

  # alias MastaniServer.{Accounts}
  setup do
    {:ok, user} = db_insert(:user)

    user_conn = simu_conn(:user)
    guest_conn = simu_conn(:guest)

    {:ok, ~m(user_conn guest_conn user)a}
  end

  describe "[account messages queries]" do
    @query """
    query {
      account {
        id
        mailBox {
          hasMail
          totalCount
          mentionCount
          notificationCount
        }
      }
    }
    """
    test "login user can get mail box status" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      result = user_conn |> query_result(@query, %{}, "account")
      mailBox = result["mailBox"]
      assert mailBox["hasMail"] == false
      assert mailBox["totalCount"] == 0
      assert mailBox["mentionCount"] == 0
      assert mailBox["notificationCount"] == 0

      mock_mentions_for(user, 2)
      mock_notifications_for(user, 18)

      result = user_conn |> query_result(@query, %{}, "account")
      mailBox = result["mailBox"]
      assert mailBox["hasMail"] == true
      assert mailBox["totalCount"] == 20
      assert mailBox["mentionCount"] == 2
      assert mailBox["notificationCount"] == 18
    end

    test "unauth user get mailBox status fails", ~m(guest_conn)a do
      variables = %{}

      assert guest_conn |> query_get_error?(@query, variables, ecode(:account_login))
    end

    @query """
    query($filter: MessagesFilter!) {
      account {
        id
        mentions(filter: $filter) {
          entries {
            id
            fromUserId
            toUserId
            read
          }
          totalCount
        }
        notifications(filter: $filter) {
          entries {
            id
            fromUserId
            toUserId
            read
          }
          totalCount
        }
        sysNotifications(filter: $filter) {
          entries {
            id
            read
          }
          totalCount
        }
      }
    }
    """
    test "user can get mentions send by others" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      variables = %{filter: %{page: 1, size: 20, read: false}}
      result = user_conn |> query_result(@query, variables, "account")
      mentions = result["mentions"]
      assert mentions["totalCount"] == 0

      mock_mentions_for(user, 3)

      variables = %{filter: %{page: 1, size: 20, read: false}}
      result = user_conn |> query_result(@query, variables, "account")
      mentions = result["mentions"]

      assert mentions["totalCount"] == 3
      assert mentions["entries"] |> List.first() |> Map.get("toUserId") == to_string(user.id)
    end

    test "user can get notifications send by others" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      variables = %{filter: %{page: 1, size: 20, read: false}}
      result = user_conn |> query_result(@query, variables, "account")
      notifications = result["notifications"]
      assert notifications["totalCount"] == 0

      mock_notifications_for(user, 3)

      variables = %{filter: %{page: 1, size: 20, read: false}}
      result = user_conn |> query_result(@query, variables, "account")
      notifications = result["notifications"]

      assert notifications["totalCount"] == 3
      assert notifications["entries"] |> List.first() |> Map.get("toUserId") == to_string(user.id)
    end

    test "user can get system notifications" do
      {:ok, user} = db_insert(:user)
      user_conn = simu_conn(:user, user)

      variables = %{filter: %{page: 1, size: 20, read: false}}
      result = user_conn |> query_result(@query, variables, "account")
      notifications = result["sysNotifications"]
      assert notifications["totalCount"] == 0

      mock_sys_notification(5)

      variables = %{filter: %{page: 1, size: 20, read: false}}
      result = user_conn |> query_result(@query, variables, "account")
      notifications = result["sysNotifications"]

      assert notifications["totalCount"] == 5
    end
  end
end
