# Copyright © 2018 Jonathan Storm <jds@idio.link> This work
# is free. You can redistribute it and/or modify it under
# the terms of the Do What The Fuck You Want To Public
# License, Version 2, as published by Sam Hocevar. See the
# COPYING.WTFPL file for more details.

defmodule TAP do
  use GenServer

  ### Public API ###

  @spec start_link
    :: {:ok, pid} | {:error, any}
  @spec start_link(binary)
    :: {:ok, pid} | {:error, any}
  def start_link(if_name \\ "") do
    GenServer.start_link(__MODULE__, [%{if_name: if_name}])
  end

  @spec get_interface(pid)
    :: binary
  def get_interface(pid) when is_pid(pid) do
    GenServer.call(pid, :get_interface)
  end

  @spec receive(pid)
    :: {:ok, binary}
     | {:error, :enodata}
  def receive(pid) when is_pid(pid) do
    GenServer.call(pid, :receive)
  end

  @doc """
  Send `data` via the running TAP process `pid`.

  Sending a frame containing less than 14 bytes will quietly
  explode the tuncer process, destroying the corresponding
  TAP interface. Sending a frame with more than 4193920
  bytes has the same effect. To avoid such subtleties, I've
  chosen to clarify both constraints with guards.

  Of course, none of this means you should actually send
  4193920 bytes, and interfaces aren't usually configured to
  accept more than 1532 bytes anyway (MTU + 802.3 + 802.1Q +
  etc.).
  """
  @spec send(pid, binary)
    :: :ok
  def send(pid, data)
      when is_pid(pid)
       and is_binary(data)
       and byte_size(data) >= 14
       and byte_size(data) <= 4193920
  do
    GenServer.call pid, {:send, data}
  end

  @spec stop(pid)
    :: :ok
  def stop(pid) when is_pid(pid) do
    GenServer.stop(pid)
  end


  ### Private API ###

  def init([opts]) do
    try do
      parameters = [:tap, :no_pi, {:active, true}]
      {:ok, pid} =
        :tuncer.create(opts.if_name, parameters)

      state = %{interface_pid: pid, queue: []}

      {:ok, state}

    rescue
      e in MatchError ->
        {:stop, e}
    end
  end

  def handle_info(
    {:tuntap, interface_pid, data},
    %{interface_pid: interface_pid, queue: queue} = state
  ) do
    new_queue = queue ++ [data]
    new_state = %{state|queue: new_queue}

    {:noreply, new_state}
  end

  def handle_info(
    {:tuntap_error, interface_pid, :eio},
    %{interface_pid: interface_pid}
  ) do
    {:stop, :enetdown, nil}
  end

  def handle_call(
    {:send, data},
    _from,
    %{interface_pid: interface_pid} = state
  ) do
    :ok = :tuncer.send(interface_pid, data)

    {:reply, :ok, state}
  end

  def handle_call(
    :get_interface,
    _from,
    %{interface_pid: interface_pid} = state
  ) do
    interface = :tuncer.devname(interface_pid)

    {:reply, interface, state}
  end

  def handle_call(
    :receive,
    _from,
    %{queue: []} = state
  ) do
    {:reply, {:error, :enodata}, state}
  end

  def handle_call(
    :receive,
    _from,
    %{queue: [pdu | next_queue]} = state
  ) do
    new_state = %{state|queue: next_queue}

    {:reply, {:ok, pdu}, new_state}
  end

  def terminate(:enetdown, _),
    do: nil

  def terminate(_, %{interface_pid: interface_pid}) do
    :tuncer.destroy interface_pid
  end
end
