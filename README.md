# tap-elixir

[![Build Status](https://travis-ci.org/jonnystorm/tap-elixir.svg?branch=master)](https://travis-ci.org/jonnystorm/tap-elixir)

Perform raw send/receive over a Linux TAP interface.

`tap_ex` is just a tiny wrapper for [msantos](https://github.com/msantos)'s Erlang library, [tunctl](https://github.com/msantos/tunctl).

In the future, tap-elixir should probably bypass tunctl and interact directly with [procket](https://github.com/msantos/tunctl).


## Why?

I've written `tap_ex` largely for mnemonic purposes and experimentation, but I hope blazing my trail will help someone else.
Early on, I nearly gave up on [tunctl](https://github.com/msantos/tunctl) because of a few critical missteps and a dearth of examples.


## Installation

  1. Add `tap_ex` to your list of dependencies in `mix.exs`:

        def deps do
          [ {:tap_ex, git: "https://github.com/jonnystorm/tap-elixir.git"}
          ]
        end

  2. Ensure `tap_ex` is started before your application:

        def application do
          [ applications: [
              :tap_test
            ]
          ]
        end


## Usage

    iex> {:ok, pid} = TAP.start
    {:ok, #PID<0.112.0>}

    iex> TAP.get_interface pid
    "tap0"

    iex> TAP.send pid, <<0xffffffffffff :: 6*8, 0xc0ff33c0ff33 :: 6*8, 0x0005 :: 2*8, "stuff">>
    :ok

    iex> TAP.receive pid
    {:ok, <<51, 51, 0, 0, 0, 22, 190, 193, 149, 238, 53, 157, 134, 221, 96, 0, 0, 0, 0, 36, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 255, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, ...>>}
    iex> TAP.receive pid
    {:error, :enodata}

    iex> TAP.stop pid
    :ok


## Setting privileges

To allow the BEAM to create TAP interfaces, try

    sudo setcap cap_net_admin=ep /path/to/bin/beam


## Two TAPs--ah, ha-ha!

A good way to let two TAP processes communicate is to bridge their interfaces.
The provided helper script, `bridge-helper.sh`, does this for `tap0` and `tap1`.
While this can technically be done with [tunctl](https://github.com/msantos/tunctl), I haven't yet sorted how to bring up interfaces without assigning IPs.

Only messages containing a valid unicast source MAC address can traverse the bridge and populate the forwarding database.
This means frames with an all-zeros source address, or with the ones bit set in the left-most (most significant) byte of the source address, won't appear in `tcpdump -i br0`.

If all goes well, `bridge fdb` will show a corresponding entry.
Otherwise, `tcpdump -eln -s0 -i tap0` (or `tap1`), or some variation, is your friend.

Once finished, the resulting bridge interface may be removed by issuing

    ip link del dev br0 type bridge


## Whereof one cannot speak

Sending over a down TAP interface will cause the **linked** GenServer to `:EXIT`.
This is more intrusive than merely emitting a message as `tuncer` does in Active mode, but the feedback is obvious and immediate.

Sending a frame containing less than 14 bytes will quietly explode the `tuncer` process, destroying the corresponding TAP interface.
Sending a frame with more than 4193920 bytes will do the same.
In both cases, I've chosen to clarify these constraints with guards.

Of course, none of this means you should actually send 4193920 bytes, and interfaces aren't usually configured to accept more than 1532 bytes anyway (MTU + 802.3 + 802.1ad + ...).

As a reminder, the EthernetV2 (DIX) frame structure is

    << dst :: 8*6,
       src :: 8*6,
      type :: 8*2,
      data :: binary
    >>

Beyond that, do what you like; a surprising number of devices will eat whatever you give them, for better or worse.

