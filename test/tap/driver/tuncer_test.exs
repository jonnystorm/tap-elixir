# Copyright © 2016 Jonathan Storm <the.jonathan.storm@gmail.com>
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See the COPYING.WTFPL file for more details.

defmodule TAP.Driver.TuncerTest do
  use ExUnit.Case, async: true

  @moduletag :driver

  setup do
    {:ok, pid} = TAP.Driver.Tuncer.create

    {:ok, driver_pid: pid}
  end

  test "Tuncer quietly explodes when sending over down TAP", %{driver_pid: pid} do
    assert :tuncer.send(pid, <<0 :: 14*8>>) == :ok

    assert_receive {:tuntap_error, _, :eio}

    :timer.sleep 50
    assert Process.alive?(pid) == false
  end

  test "Driver quietly explodes when sending over down TAP", %{driver_pid: pid} do
    assert TAP.Driver.Tuncer.send(pid, <<0 :: 14*8>>) == :ok

    assert_receive {:tuntap_error, _, :eio}

    :timer.sleep 50
    assert Process.alive?(pid) == false
  end

  test "Tuncer quietly explodes when sending too little data", %{driver_pid: pid} do
    assert :tuncer.send(pid, <<0 :: 13*8>>) == :ok

    assert_receive {:tuntap_error, _, :eio}

    :timer.sleep 50
    assert Process.alive?(pid) == false
  end

  test "Driver raises when sending too little data", %{driver_pid: pid} do
    assert_raise FunctionClauseError, fn ->
      TAP.Driver.Tuncer.send pid, <<0 :: 13*8>>
    end
  end

  test "Tuncer quietly explodes when sending too much data", %{driver_pid: pid} do
    assert :tuncer.send(pid, <<0 :: 4193921*8>>) == :ok

    assert_receive {:tuntap_error, _, :eio}

    :timer.sleep 50
    assert Process.alive?(pid) == false
  end

  test "Driver raises when sending too much data", %{driver_pid: pid} do
    assert_raise FunctionClauseError, fn ->
      TAP.Driver.Tuncer.send pid, <<0 :: 4193921*8>>
    end
  end

  test "Tuncer raises when sending bitstring as data", %{driver_pid: pid} do
    bits = 14 * 8 + 1

    assert_raise FunctionClauseError, fn ->
      :tuncer.send pid, <<0 :: size(bits)>>
    end
  end

  test "Driver raises when sending bitstring as data", %{driver_pid: pid} do
    bits = 14 * 8 + 1

    assert_raise FunctionClauseError, fn ->
      TAP.Driver.Tuncer.send pid, <<0 :: size(bits)>>
    end
  end
end
