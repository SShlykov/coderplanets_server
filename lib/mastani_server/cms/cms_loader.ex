defmodule MastaniServer.CMS.Loader do
  import Ecto.Query, warn: false

  alias MastaniServer.Repo
  alias Helper.QueryBuilder

  alias MastaniServer.CMS.{
    Author,
    Post,
    PostComment,
    PostFavorite,
    PostStar,
    CommunitySubscriber,
    CommunityEditor,
    CommunityThread
  }

  def data(), do: Dataloader.Ecto.new(Repo, query: &query/2, run_batch: &run_batch/5)

  # Big thanks: https://elixirforum.com/t/grouping-error-in-absinthe-dadaloader/13671/2
  # see also: https://github.com/absinthe-graphql/dataloader/issues/25
  def run_batch(Post, post_query, :posts_count, community_ids, repo_opts) do
    query =
      from(
        p in post_query,
        join: c in assoc(p, :communities),
        where: c.id in ^community_ids,
        group_by: c.id,
        select: {c.id, [count(p.id)]}
      )

    results =
      query
      |> Repo.all(repo_opts)
      |> Map.new()

    for id <- community_ids, do: Map.get(results, id, [0])
  end

  def query(Author, _args) do
    # you cannot use preload with select together
    # https://stackoverflow.com/questions/43010352/ecto-select-relations-from-preload
    # see also
    # https://github.com/elixir-ecto/ecto/issues/1145
    from(a in Author, join: u in assoc(a, :user), select: u)
  end

  def query({"communities_threads", CommunityThread}, _info) do
    from(ct in CommunityThread, join: t in assoc(ct, :thread), select: t)
  end

  def query({"posts_comments", PostComment}, %{filter: filter}) do
    PostComment |> QueryBuilder.filter_pack(filter)
  end

  @doc """
  handle query:
  1. bacic filter of pagi,when,sort ...
  2. count of the reactions
  3. check is viewer reacted
  """
  def query({"posts_favorites", PostFavorite}, args) do
    PostFavorite |> QueryBuilder.members_pack(args)
  end

  def query({"posts_stars", PostStar}, args) do
    PostStar |> QueryBuilder.members_pack(args)
  end

  def query({"communities_subscribers", CommunitySubscriber}, args) do
    CommunitySubscriber |> QueryBuilder.members_pack(args)
  end

  def query({"communities_editors", CommunityEditor}, args) do
    CommunityEditor |> QueryBuilder.members_pack(args)
  end

  def query(queryable, _args) do
    queryable
  end
end
