# Copyright © 2016 Jonathan Storm <the.jonathan.storm@gmail.com>
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See the COPYING.WTFPL file for more details.

defmodule TAP.Driver.Dummy do
  @behaviour TAP.Driver

  def create do
    {:ok, :c.pid(0, 999, 0)}
  end

  def destroy(pid) when is_pid pid do
    :ok
  end

  def send(pid, data)
      when is_pid(pid)
       and is_binary(data)
       and byte_size(data) >= 14
       and byte_size(data) <= 4193920 do

    :ok
  end

  def get_interface(pid) when is_pid pid do
    "tap0"
  end
end
