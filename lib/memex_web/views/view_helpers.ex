defmodule MemexWeb.ViewHelpers do
  @moduledoc """
  Contains common helpers that can be used in liveviews and regular views. These
  are automatically imported into any Phoenix View using `use MemexWeb,
  :view`
  """

  use Phoenix.Component

  @doc """
  Displays content in a QR code as a base64 encoded PNG
  """
  @spec qr_code_image(String.t()) :: String.t()
  @spec qr_code_image(String.t(), width :: non_neg_integer()) :: String.t()
  def qr_code_image(content, width \\ 384) do
    img_data =
      content
      |> EQRCode.encode()
      |> EQRCode.png(width: width, background_color: <<24, 24, 27>>, color: <<255, 255, 255>>)
      |> Base.encode64()

    "data:image/png;base64," <> img_data
  end
end
