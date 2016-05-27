# Copyright © 2016 Jonathan Storm <the.jonathan.storm@gmail.com>
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See the COPYING.WTFPL file for more details.

defmodule TuncerTest do
  use ExUnit.Case, async: true

  @moduletag :integrated

  setup do
    {:ok, pid} = :tuncer.create "", [:tap, :no_pi, {:active, true}]

    {:ok, an_pid: pid}
  end

  test "tuncer quietly explodes when sending over down TAP", %{an_pid: pid} do
    assert :tuncer.send(pid, <<0 :: 14*8>>) == :ok

    assert_receive {:tuntap_error, _, :eio}

    :timer.sleep 50
    assert Process.alive?(pid) == false
  end

  test "tuncer quietly explodes when sending too little data", %{an_pid: pid} do
    assert :tuncer.send(pid, <<0 :: 13*8>>) == :ok

    assert_receive {:tuntap_error, _, :eio}

    :timer.sleep 50
    assert Process.alive?(pid) == false
  end

  test "tuncer quietly explodes when sending too much data", %{an_pid: pid} do
    assert :tuncer.send(pid, <<0 :: 4193921*8>>) == :ok

    assert_receive {:tuntap_error, _, :eio}

    :timer.sleep 50
    assert Process.alive?(pid) == false
  end

  test "tuncer raises when sending bitstring as data", %{an_pid: pid} do
    bits = 14 * 8 + 1

    assert_raise FunctionClauseError, fn ->
      :tuncer.send pid, <<0 :: size(bits)>>
    end
  end
end

