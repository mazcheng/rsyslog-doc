imptcp: Plain TCP Syslog
========================

Provides the ability to receive syslog messages via plain TCP syslog.
This is a specialised input plugin tailored for high performance on
Linux. It will probably not run on any other platform. Also, it does not
provide TLS services. Encryption can be provided by using
`stunnel <rsyslog_stunnel.html>`_.

This module has no limit on the number of listeners and sessions that
can be used.

**Author:** Rainer Gerhards <rgerhards@adiscon.com>

Error Messages
--------------

When a message is to long it will be truncated and an error will show the remaining length of the message and the beginning of it. It will be easier to comprehend the truncation.

Configuration Directives
------------------------

This plugin has config directives similar named as imtcp, but they all
have **P**\ TCP in their name instead of just TCP. Note that only a
subset of the parameters are supported.

Module Parameters
^^^^^^^^^^^^^^^^^

Note: parameter names are case-insensitive.

These parameters can be used with the "module()" statement. They apply
globaly to all inputs defined by the module.

.. function:: Threads <number>

   Number of helper worker threads to process incoming messages. These
   threads are utilized to pull data off the network. On a busy system,
   additional helper threads (but not more than there are CPUs/Cores)
   can help improving performance. The default value is two, which means
   there is a default thread count of three (the main input thread plus
   two helpers). No more than 16 threads can be set (if tried to,
   rsyslog always resorts to 16).

.. function:: processOnPoller on/off

   *Defaults to on*

   Instructs imptcp to process messages on poller thread opportunistically.
   This leads to lower resource footprint(as poller thread doubles up as
   message-processing thread too). "On" works best when imptcp is handling
   low ingestion rates.

   At high throughput though, it causes polling delay(as poller spends time
   processing messages, which keeps connections in read-ready state longer
   than they need to be, filling socket-buffer, hence eventually applying
   backpressure).

   It defaults to allowing messages to be processed on poller (for backward
   compatibility).

Input Parameters
^^^^^^^^^^^^^^^^

Note: parameter names are case-insensitive.

These parameters can be used with the "input()" statement. They apply to
the input they are specified with.

.. function:: port <number>

   *Mandatory*

   Select a port to listen on. It is an error to specify
   both `path` and `port`.

.. function:: path <name>

   A path on the filesystem for a unix domain socket. It is an error to specify
   both `path` and `port`.

.. function:: discardTruncatedMsg <on/off>

   *Default: off*

   When a message is split because it is to long the second part is normally
   processed as the next message. This can cause Problems. When this parameter
   is turned on the part of the message after the truncation will be discarded.

.. function::  fileOwner [userName]

   *Default: system default*

   Set the file owner for the domain socket. The
   parameter is a user name, for which the userid is obtained by
   rsyslogd during startup processing. Interim changes to the user
   mapping are *not* detected.

.. function::  fileOwnerNum [uid]

   *Default: system default*

   Set the file owner for the domain socket. The
   parameter is a numerical ID, which which is used regardless of
   whether the user actually exists. This can be useful if the user
   mapping is not available to rsyslog during startup.

.. function::  fileGroup [groupName]

   *Default: system default*

   Set the group for the domain socket. The parameter is
   a group name, for which the groupid is obtained by rsyslogd during
   startup processing. Interim changes to the user mapping are not
   detected.

.. function::  fileGroupNum [gid]

   *Default: system default*

   Set the group for the domain socket. The parameter is
   a numerical ID, which is used regardless of whether the group
   actually exists. This can be useful if the group mapping is not
   available to rsyslog during startup.

.. function::  fileCreateMode [octalNumber]

   *Default: 0644*

   Set the access permissions for the domain socket. The value given must
   always be a 4-digit octal number, with the initial digit being zero.
   Please note that the actual permission depend on rsyslogd's process
   umask. If in doubt, use "$umask 0000" right at the beginning of the
   configuration file to remove any restrictions.

.. function::  failOnChOwnFailure [switch]

   *Default: on*

   rsyslog will not start if this is on and changing the file owner, group,
   or access permissions fails. Disable this to ignore these errors.

.. function:: unlink on/off

   *Default: off*

   If a unix domain socket is being used this controls whether or not the socket
   is unlinked before listening and after closing.

.. function:: name <name>

   Sets a name for the inputname property. If no name is set "imptcp"
   is used by default. Setting a name is not strictly necessary, but can
   be useful to apply filtering based on which input the message was
   received from. Note that the name also shows up in
   :doc:`impstats <impstats>` logs.

.. function:: ruleset <name>

   Binds specified ruleset to this input. If not set, the default
   ruleset is bound.

.. function:: maxFrameSize <int>

   *Default: 200000; Max: 200000000*

   When in octet counted mode, the frame size is given at the beginning
   of the message. With this parameter the max size this frame can have
   is specified and when the frame gets to large the mode is switched to
   octet stuffing.
   The max value this parameter can have was specified because otherwise
   the integer could become negative and this would result in a
   Segmentation Fault.

.. function:: address <name>

   *Default: all interfaces*

   On multi-homed machines, specifies to which local address the
   listerner should be bound.

.. function:: AddtlFrameDelimiter <Delimiter>

   This directive permits to specify an additional frame delimiter for
   plain tcp syslog. The industry-standard specifies using the LF
   character as frame delimiter. Some vendors, notable Juniper in their
   NetScreen products, use an invalid frame delimiter, in Juniper's case
   the NUL character. This directive permits to specify the ASCII value
   of the delimiter in question. Please note that this does not
   guarantee that all wrong implementations can be cured with this
   directive. It is not even a sure fix with all versions of NetScreen,
   as I suggest the NUL character is the effect of a (common) coding
   error and thus will probably go away at some time in the future. But
   for the time being, the value 0 can probably be used to make rsyslog
   handle NetScreen's invalid syslog/tcp framing. For additional
   information, see this `forum
   thread <http://kb.monitorware.com/problem-with-netscreen-log-t1652.html>`_.
   **If this doesn't work for you, please do not blame the rsyslog team.
   Instead file a bug report with Juniper!**

   Note that a similar, but worse, issue exists with Cisco's IOS
   implementation. They do not use any framing at all. This is confirmed
   from Cisco's side, but there seems to be very limited interest in
   fixing this issue. This directive **can not** fix the Cisco bug. That
   would require much more code changes, which I was unable to do so
   far. Full details can be found at the `Cisco tcp syslog
   anomaly <http://www.rsyslog.com/Article321.phtml>`_ page.

.. function:: SupportOctetCountedFraming on/off

   *Defaults to "on"*

   The legacy octed-counted framing (similar to RFC5425
   framing) is activated. This is the default and should be left
   unchanged until you know very well what you do. It may be useful to
   turn it off, if you know this framing is not used and some senders
   emit multi-line messages into the message stream.

.. function:: NotifyOnConnectionClose on/off

   *Defaults to off*

   instructs imptcp to emit a message if a remote peer closes the
   connection.

.. function:: NotifyOnConnectionOpen on/off

   *Defaults to off*

   instructs imptcp to emit a message if a remote peer opens a
   connection. Hostname of the remote peer is given in the message.

.. function:: KeepAlive on/off

   *Defaults to off*

   enable of disable keep-alive packets at the tcp socket layer. The
   default is to disable them.

.. function:: KeepAlive.Probes <number>

   The number of unacknowledged probes to send before considering the
   connection dead and notifying the application layer. The default, 0,
   means that the operating system defaults are used. This has only
   effect if keep-alive is enabled. The functionality may not be
   available on all platforms.

.. function:: KeepAlive.Interval <number>

   The interval between subsequential keepalive probes, regardless of
   what the connection has exchanged in the meantime. The default, 0,
   means that the operating system defaults are used. This has only
   effect if keep-alive is enabled. The functionality may not be
   available on all platforms.

.. function:: KeepAlive.Time <number>

   The interval between the last data packet sent (simple ACKs are not
   considered data) and the first keepalive probe; after the connection
   is marked to need keepalive, this counter is not used any further.
   The default, 0, means that the operating system defaults are used.
   This has only effect if keep-alive is enabled. The functionality may
   not be available on all platforms.

.. function:: RateLimit.Interval [number]

   *Default is 0, which turns off rate limiting*

   Specifies the rate-limiting interval in seconds. Set it to a number
   of seconds (5 recommended) to activate rate-limiting.

.. function:: RateLimit.Burst [number]

   *Default is 10,000*

   Specifies the rate-limiting burst in number of messages.

.. function:: compression.mode [mode]

   *Default is none*

   This is the counterpart to the compression modes set in
   :doc:`omfwd <omfwd>`.
   Please see it's documentation for details.

.. function:: flowControl <on/off>

   *Default: on*

   Flow control is used to throttle the sender if the receiver queue is
   near-full preserving some space for input that can not be throttled.

.. function:: multiLine <on/off>

   *Default: off*

   Experimental parameter which caues rsyslog to recognise a new message
   only if the line feed is followed by a '<' or if there are no more characters.

Statistic Counter
-----------------

This plugin maintains :doc:`statistics <../rsyslog_statistic_counter>` for each listener. The statistic is
named "imtcp" , followed by the bound address, listener port and IP
version in parenthesis. For example, the counter for a listener on port
514, bound to all interfaces and listening on IPv6 is called
"imptcp(\*/514/IPv6)".

The following properties are maintained for each listener:

-  **submitted** - total number of messages submitted for processing since startup

Caveats/Known Bugs
------------------

-  module always binds to all interfaces

Example
-------

This sets up a TCP server on port 514:

::

  module(load="imptcp") # needs to be done just once
  input(type="imptcp" port="514")

This creates a listener that listens on the local loopback
interface, only.

::

  module(load="imptcp") # needs to be done just once
  input(type="imptcp" port="514" address="127.0.0.1")

Create a unix domain socket:

::

  module(load="imptcp") # needs to be done just once
  input(type="imptcp" path="/tmp/unix.sock" unlink="on")

Legacy Configuration Directives
-------------------------------

.. function:: $InputPTCPServerAddtlFrameDelimiter <Delimiter>

   Equivalent to: AddTLFrameDelimiter

.. function:: $InputPTCPSupportOctetCountedFraming on/off

   Equivalent to: SupportOctetCountedFraming

.. function:: $InputPTCPServerNotifyOnConnectionClose on/off

   Equivalent to: NotifyOnConnectionClose.

.. function:: $InputPTCPServerKeepAlive <on/**off**>

   Equivalent to: KeepAlive

.. function:: $InputPTCPServerKeepAlive\_probes <number>

   Equivalent to: KeepAlive.Probes

.. function:: $InputPTCPServerKeepAlive\_intvl <number>

   Equivalent to: KeepAlive.Interval

.. function:: $InputPTCPServerKeepAlive\_time <number>

   Equivalent to: KeepAlive.Time

.. function:: $InputPTCPServerRun <port>

   Equivalent to: Port

.. function:: $InputPTCPServerInputName <name>

   Equivalent to: Name

.. function:: $InputPTCPServerBindRuleset <name>

   Equivalent to: Ruleset

.. function:: $InputPTCPServerHelperThreads <number>

   Equivalent to: threads

.. function:: $InputPTCPServerListenIP <name>

   Equivalent to: Address

Caveats/Known Bugs
------------------

-  module always binds to all interfaces

Example
--------

This sets up a TCP server on port 514:

::

  $ModLoad imptcp # needs to be done just once
  $InputPTCPServerRun 514

