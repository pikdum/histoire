defmodule Histoire.Nyaa do
  use Ash.Domain, otp_app: :histoire, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource Histoire.Nyaa.Torrent
    resource Histoire.Nyaa.File
  end
end
