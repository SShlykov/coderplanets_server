defmodule MastaniServer.Repo.Migrations.CreatePostsComments do
  use Ecto.Migration

  def change do
    create table(:posts_comments) do
      add(:body, :string)
      add(:writer_id, references(:users, on_delete: :delete_all), null: false)
      add(:post_id, references(:cms_posts, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:posts_comments, [:writer_id]))
    create(index(:posts_comments, [:post_id]))
    create(unique_index(:posts_comments, [:writer_id, :post_id]))
  end
end
