# Copyright © 2016 Jonathan Storm <the.jonathan.storm@gmail.com>
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See the COPYING.WTFPL file for more details.

defmodule TAPTest do
  use ExUnit.Case, async: true

  require Logger

  setup do
    {:ok, pid} = TAP.start

    {:ok, tap_pid: pid}
  end

  test "Sends data", %{tap_pid: pid} do
    assert TAP.send(pid, <<0 :: 14*8>>) == :ok
  end

  test "Raises when sending too little data", %{tap_pid: pid} do
    catch_exit(TAP.send pid, <<0 :: 13*8>>)
  end

  test "Raises when sending too much data", %{tap_pid: pid} do
    catch_exit(TAP.send pid, <<0 :: 4193921*8>>)
  end

  test "Raises when sending bitstring as data", %{tap_pid: pid} do
    bits = 14 * 8 + 1

    assert_raise FunctionClauseError, fn ->
      TAP.send pid, <<0 :: size(bits)>>
    end
  end

  test "Stops process", %{tap_pid: pid} do
    assert TAP.stop(pid) == :ok

    assert Process.alive?(pid) == false
  end
end
