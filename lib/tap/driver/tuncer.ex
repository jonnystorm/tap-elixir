# Copyright © 2016 Jonathan Storm <the.jonathan.storm@gmail.com>
# This work is free. You can redistribute it and/or modify it under the
# terms of the Do What The Fuck You Want To Public License, Version 2,
# as published by Sam Hocevar. See the COPYING.WTFPL file for more details.

defmodule TAP.Driver.Tuncer do
  @behaviour TAP.Driver

  def create do
    :tuncer.create '', [:tap, :no_pi, {:active, true}]
  end

  def destroy(pid) when is_pid pid do
    :tuncer.destroy pid
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
  def send(pid, data)
      when is_pid(pid)
       and is_binary(data)
       and byte_size(data) >= 14
       and byte_size(data) <= 4193920 do

    :tuncer.send pid, data
  end

  def get_interface(pid) when is_pid pid do
    :tuncer.devname pid
  end
end
