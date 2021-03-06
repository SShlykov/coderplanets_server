defmodule GroupherServer.Accounts do
  @moduledoc false

  alias GroupherServer.Accounts.Delegate.{
    Achievements,
    Customization,
    Fans,
    FavoriteCategory,
    Publish,
    Mails,
    Profile,
    ReactedContents,
    Search
  }

  # profile
  defdelegate update_profile(user, attrs), to: Profile
  defdelegate update_geo(user, remote_ip), to: Profile
  defdelegate github_signin(github_user), to: Profile
  defdelegate default_subscribed_communities(filter), to: Profile
  defdelegate subscribed_communities(user, filter), to: Profile

  # favorite category
  defdelegate list_favorite_categories(user, opt, filter), to: FavoriteCategory
  defdelegate create_favorite_category(user, attrs), to: FavoriteCategory
  defdelegate update_favorite_category(user, attrs), to: FavoriteCategory
  defdelegate delete_favorite_category(user, id), to: FavoriteCategory
  defdelegate set_favorites(user, thread, content_id, category_id), to: FavoriteCategory
  defdelegate unset_favorites(user, thread, content_id, category_id), to: FavoriteCategory

  # achievement
  defdelegate achieve(user, operation, key), to: Achievements
  defdelegate list_editable_communities(user, filter), to: Achievements
  defdelegate downgrade_achievement(user, action, count), to: Achievements
  # defdelegate list_editable_communities(filter), to: Achievements

  # publish
  defdelegate published_contents(user, thread, filter), to: Publish
  defdelegate published_comments(user, thread, filter), to: Publish

  # fans
  defdelegate follow(user, follower), to: Fans
  defdelegate undo_follow(user, follower), to: Fans
  defdelegate fetch_followers(user, filter), to: Fans
  defdelegate fetch_followings(user, filter), to: Fans

  # reacted contents
  defdelegate reacted_contents(thread, react, filter, user), to: ReactedContents
  defdelegate reacted_contents(thread, react, category_id, filter, user), to: ReactedContents

  # mentions
  defdelegate fetch_mentions(user, filter), to: Mails

  # notifications
  defdelegate fetch_notifications(user, filter), to: Mails
  defdelegate fetch_sys_notifications(user, filter), to: Mails

  # common message
  defdelegate mailbox_status(user), to: Mails
  defdelegate mark_mail_read_all(user, opt), to: Mails
  defdelegate mark_mail_read(mail, user), to: Mails

  # customization
  defdelegate get_customization(user), to: Customization
  defdelegate set_customization(user, key, value), to: Customization
  defdelegate set_customization(user, options), to: Customization
  defdelegate upgrade_by_plan(user, plan), to: Customization

  defdelegate search_users(args), to: Search
end
