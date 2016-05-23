# Copyright © 2016 Jonathan Storm <the.jonathan.storm@gmail.com>
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See the COPYING.WTFPL file for more details.

defmodule TAP do
  require Logger

  use GenServer

  @driver Application.get_env :tap_ex, :driver


  ### Public API ###

  @spec start :: {:ok, pid} | {:error, any}
  def start do
    GenServer.start __MODULE__, []
  end

  @spec get_interface(pid) :: binary
  def get_interface(pid) when is_pid(pid) do
    GenServer.call pid, :get_interface
  end

  @spec receive(pid) :: {:ok, binary} | {:error, :enodata}
  def receive(pid) when is_pid(pid) do
    GenServer.call pid, :receive
  end

  @spec send(pid, binary) :: :ok
  def send(pid, data) when is_pid(pid) and is_binary(data) do
    GenServer.call pid, {:send, data}
  end

  @spec stop(pid) :: :ok
  def stop(pid) when is_pid pid do
    GenServer.stop pid
  end


  ### Private API ###

  def init(_) do
    {:ok, pid} = @driver.create

    state = %{if_pid: pid, queue: []}

    {:ok, state}
  end

  def handle_info({:tuntap, if_pid, data}, %{if_pid: if_pid} = state) do
    new_state =
      %{state |
        queue: state[:queue] ++ [data]
      }

    {:noreply, new_state}
  end
  def handle_info({:tuntap_error, if_pid, :eio}, %{if_pid: if_pid}) do
    raise "Attempted to send over down interface."
  end

  def handle_call({:send, data}, _from, %{if_pid: if_pid} = state) do
    :ok = @driver.send if_pid, data

    {:reply, :ok, state}
  end
  def handle_call(:get_interface, _from, %{if_pid: if_pid} = state) do
    interface = @driver.get_interface if_pid

    {:reply, interface, state}
  end
  def handle_call(:receive, _from, %{queue: []} = state) do
    {:reply, {:error, :enodata}, state}
  end
  def handle_call(:receive, _from, %{queue: [pdu | queue]} = state) do
    new_state = %{state | queue: queue}

    {:reply, {:ok, pdu}, new_state}
  end

  def terminate(_, %{if_pid: if_pid}) do
    @driver.destroy if_pid
  end
end
