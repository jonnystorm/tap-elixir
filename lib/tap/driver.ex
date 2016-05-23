defmodule TAP.Driver do
  @callback create :: {:ok, pid} | {:error, any}

  @callback destroy(pid :: pid) :: :ok

  @callback send(pid :: pid, data :: binary) :: :ok | {:error, any}

  @callback get_interface(pid :: pid) :: {:ok, binary}
end
