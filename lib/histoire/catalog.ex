defmodule Histoire.Catalog do
  use Ash.Domain, otp_app: :histoire, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource Histoire.Catalog.SubsPleaseTVDBShowMatch
    resource Histoire.Catalog.SubsPleaseNyaaDownloadOverride
    resource Histoire.Catalog.Matcher
  end
end
