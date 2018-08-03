# Copyright © 2018 Jonathan Storm <jds@idio.link>
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See the COPYING.WTFPL file for more details.

defmodule TAPTest do
  use ExUnit.Case, async: true

  @moduletag :integrated

  setup do
    {:ok, pid} = TAP.start_link

    {:ok, tap_pid: pid}
  end

  test "TAP exits when sending over down interface",
       %{tap_pid: pid}
  do
    Process.flag(:trap_exit, true)

    assert TAP.send(pid, <<0::14*8>>) == :ok

    assert_receive {:EXIT, pid, :enetdown}

    :timer.sleep 50

    assert Process.alive?(pid) == false
  end

  test "TAP raises when sending too little data",
       %{tap_pid: pid}
  do
    assert_raise FunctionClauseError, fn ->
      TAP.send pid, <<0::13*8>>
    end
  end

  test "TAP raises when sending too much data",
       %{tap_pid: pid}
  do
    assert_raise FunctionClauseError, fn ->
      TAP.send pid, <<0::4193921*8>>
    end
  end

  test "TAP raises when sending bitstring as data",
       %{tap_pid: pid}
  do
    bits = 14 * 8 + 1

    assert_raise FunctionClauseError, fn ->
      TAP.send pid, <<0::size(bits)>>
    end
  end

  test "Stops process", %{tap_pid: pid} do
    assert TAP.stop(pid) == :ok

    assert Process.alive?(pid) == false
  end
end
