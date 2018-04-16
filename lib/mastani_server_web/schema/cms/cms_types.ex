defmodule MastaniServerWeb.Schema.CMS.Types do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: MastaniServer.Repo

  import Ecto.Query, warn: false
  import Absinthe.Resolution.Helpers, only: [dataloader: 2, on_load: 2]

  alias MastaniServer.{CMS}
  alias MastaniServerWeb.{Resolvers, Schema}
  alias MastaniServerWeb.Middleware, as: M

  import_types(Schema.CMS.Misc)

  object :comment do
    field(:id, :id)
    field(:body, :string)
    field(:author, :user, resolve: dataloader(CMS, :author))
    field(:inserted_at, :datetime)
    field(:updated_at, :datetime)
  end

  object :community_subscriber do
    field(:id, :id)
    field(:user_id, :id)
    field(:community_id, :id)
  end

  object :thread do
    field(:id, :id)
    field(:title, :string)
  end

  object :post do
    interface(:article)
    field(:id, :id)
    field(:title, :string)
    field(:digest, :string)
    field(:length, :integer)
    field(:link_addr, :string)
    field(:body, :string)
    field(:views, :integer)
    field(:tags, list_of(:tag), resolve: dataloader(CMS, :tags))
    field(:inserted_at, :datetime)
    field(:updated_at, :datetime)

    field(:author, :user, resolve: dataloader(CMS, :author))
    field(:communities, list_of(:community), resolve: dataloader(CMS, :communities))

    field :comments, list_of(:comment) do
      arg(:type, :post_type, default_value: :post)
      arg(:filter, :article_filter)
      arg(:action, :comment_action, default_value: :comment)

      middleware(M.PageSizeProof)
      resolve(dataloader(CMS, :comments))
    end

    field :viewer_has_favorited, :boolean do
      arg(:viewer_did, :viewer_did_type, default_value: :viewer_did)

      middleware(M.Authorize, :login)
      # put current user into dataloader's args
      middleware(M.PutCurrentUser)
      resolve(dataloader(CMS, :favorites))
      middleware(M.ViewerDidConvert)
      # TODO: Middleware.Logger
    end

    field :viewer_has_starred, :boolean do
      arg(:viewer_did, :viewer_did_type, default_value: :viewer_did)

      middleware(M.Authorize, :login)
      middleware(M.PutCurrentUser)
      resolve(dataloader(CMS, :stars))
      middleware(M.ViewerDidConvert)
    end

    field :favorited_users, list_of(:user) do
      arg(:filter, :members_filter)

      middleware(M.PageSizeProof)
      resolve(dataloader(CMS, :favorites))
    end

    field :favorited_count, :integer do
      arg(:count, :count_type, default_value: :count)
      arg(:type, :post_type, default_value: :post)
      # middleware(M.SeeMe)
      resolve(dataloader(CMS, :favorites))
      middleware(M.ConvertToInt)
    end

    field :starred_count, :integer do
      arg(:count, :count_type, default_value: :count)
      arg(:type, :post_type, default_value: :post)

      resolve(dataloader(CMS, :stars))
      middleware(M.ConvertToInt)
    end

    field :starred_users, list_of(:user) do
      arg(:filter, :members_filter)

      middleware(M.PageSizeProof)
      resolve(dataloader(CMS, :stars))
    end
  end

  object :paged_posts do
    field(:entries, list_of(:post))
    field(:total_count, :integer)
    field(:page_size, :integer)
    field(:total_pages, :integer)
    field(:page_number, :integer)
  end

  object :contribute do
    field(:date, :date)
    field(:count, :integer)
  end

  object :community do
    meta(:cache, max_age: 30)

    field(:id, :id)
    field(:title, :string)
    field(:desc, :string)
    field(:inserted_at, :datetime)
    field(:updated_at, :datetime)
    field(:author, :user, resolve: dataloader(CMS, :author))
    field(:threads, list_of(:thread), resolve: dataloader(CMS, :threads))

    # field :posts_count, :integer do
    # resolve(&Resolvers.CMS.community_posts_count/3)
    # end

    # Big thanks: https://elixirforum.com/t/grouping-error-in-absinthe-dadaloader/13671/2
    # see also: https://github.com/absinthe-graphql/dataloader/issues/25
    field :posts_count, :integer do
      resolve(fn community, _args, %{context: %{loader: loader}} ->
        loader
        |> Dataloader.load(CMS, {:one, CMS.Post}, posts_count: community.id)
        |> on_load(fn loader ->
          {:ok, Dataloader.get(loader, CMS, {:one, CMS.Post}, posts_count: community.id)}
        end)
      end)
    end

    field :subscribers, list_of(:user) do
      arg(:filter, :members_filter)
      middleware(M.PageSizeProof)
      resolve(dataloader(CMS, :subscribers))
    end

    field :subscribers_count, :integer do
      arg(:count, :count_type, default_value: :count)
      arg(:type, :community_type, default_value: :community)
      resolve(dataloader(CMS, :subscribers))
      middleware(M.ConvertToInt)
    end

    field :viewer_has_subscribed, :boolean do
      arg(:viewer_did, :viewer_did_type, default_value: :viewer_did)

      middleware(M.Authorize, :login)
      middleware(M.PutCurrentUser)
      resolve(dataloader(CMS, :subscribers))
      middleware(M.ViewerDidConvert)
    end

    field :editors, list_of(:user) do
      arg(:filter, :members_filter)
      middleware(M.PageSizeProof)
      resolve(dataloader(CMS, :editors))
    end

    field :editors_count, :integer do
      arg(:count, :count_type, default_value: :count)
      arg(:type, :community_type, default_value: :community)
      resolve(dataloader(CMS, :editors))
      middleware(M.ConvertToInt)
    end

    field :recent_contributes, list_of(:contribute) do
      # TODO add complex here to warning N+1 problem
      resolve(&Resolvers.Statistics.list_contributes/3)
    end
  end

  object :paged_communities do
    field(:entries, list_of(:community))
    field(:total_count, :integer)
    field(:page_size, :integer)
    field(:total_pages, :integer)
    field(:page_number, :integer)
  end

  object :tag do
    field(:id, :id)
    field(:title, :string)
    field(:color, :string)
    field(:part, :string)
    field(:inserted_at, :datetime)
    field(:updated_at, :datetime)
  end
end
