defmodule NotionHelpers.Repo do
  use Ecto.Repo,
    otp_app: :notion_helpers,
    adapter: Ecto.Adapters.Postgres
end
