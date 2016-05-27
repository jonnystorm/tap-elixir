# Copyright © 2016 Jonathan Storm <the.jonathan.storm@gmail.com>
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See the COPYING.WTFPL file for more details.

defmodule TAP do
  use GenServer

  ### Public API ###

  @spec start_link :: {:ok, pid} | {:error, any}
  @spec start_link(binary) :: {:ok, pid} | {:error, any}
  def start_link(if_name \\ "") do
    GenServer.start_link __MODULE__, [%{if_name: if_name}]
  end

  @spec get_interface(pid) :: binary
  def get_interface(pid) when is_pid(pid) do
    GenServer.call pid, :get_interface
  end

  @spec receive(pid) :: {:ok, binary} | {:error, :enodata}
  def receive(pid) when is_pid(pid) do
    GenServer.call pid, :receive
  end

  @doc """
  Sending a frame containing less than 14 bytes will quietly explode the tuncer
  process, destroying the corresponding TAP interface. Sending a frame with more
  than 4193920 bytes has the same effect. To avoid such subtleties, I've chosen
  to clarify both constraints with guards.

  Of course, none of this means you should actually send 4193920 bytes, and
  interfaces aren't usually configured to accept more than 1532 bytes anyway (MTU
   + 802.3 + 802.1Q + etc.).
  """
  @spec send(pid, binary) :: :ok
  def send(pid, data)
      when is_pid(pid)
       and is_binary(data)
       and byte_size(data) >= 14
       and byte_size(data) <= 4193920 do

    GenServer.call pid, {:send, data}
  end

  @spec stop(pid) :: :ok
  def stop(pid) when is_pid pid do
    GenServer.stop pid
  end


  ### Private API ###

  def init([opts]) do
    try do
      {:ok, pid} = :tuncer.create opts.if_name, [:tap, :no_pi, {:active, true}]

      state = %{if_pid: pid, queue: []}

      {:ok, state}

    rescue
      e in MatchError ->
        {:stop, e}
    end
  end

  def handle_info({:tuntap, if_pid, data}, %{if_pid: if_pid} = state) do
    new_state =
      %{state |
        queue: state[:queue] ++ [data]
      }

    {:noreply, new_state}
  end
  def handle_info({:tuntap_error, if_pid, :eio}, %{if_pid: if_pid}) do
    {:stop, :enetdown, nil}
  end

  def handle_call({:send, data}, _from, %{if_pid: if_pid} = state) do
    :ok = :tuncer.send if_pid, data

    {:reply, :ok, state}
  end
  def handle_call(:get_interface, _from, %{if_pid: if_pid} = state) do
    interface = :tuncer.devname if_pid

    {:reply, interface, state}
  end
  def handle_call(:receive, _from, %{queue: []} = state) do
    {:reply, {:error, :enodata}, state}
  end
  def handle_call(:receive, _from, %{queue: [pdu | queue]} = state) do
    new_state = %{state | queue: queue}

    {:reply, {:ok, pdu}, new_state}
  end

  def terminate(:enetdown, _) do
  end
  def terminate(_, %{if_pid: if_pid}) do
    :tuncer.destroy if_pid
  end
end
