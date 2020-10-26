
0.6.2 / 2015-05-14
==================

  * DOC FIX: Add secure hash key in addition to encrypted
  * FIX: Make sure to read all messages received
  * FIX: Don't hide IOError when reading from the socket

0.6.1 / 2015-05-14
==================

Same release as above but with missing changelog

0.6.0 / 2014-04-23
==================

 * options[:auth_method] for both private and presence channels
 * Relax websocket dependency to any 1.x version

0.5.0 / 2014-04-15
==================

 * Updating to protocol v6
 * Fixes scope issues with user_data
 * Makes missing user_data on presence channel error explicit
 * Mask outgoing data.
 * Update the websocket dependency to 1.1.2
 * Allow to use app_key that are symbols
 * Allow to specify the logger when creating a new Socket
 * Don't set Thread.abort_on_exception = true
 * Capture Thread exceptions when running async
 * Not raising an ArgumentError had slipped through the cracks. The test case exist.
 * Retain a consistent code style with the rest of the code and ruby's unofficial styling.
 * Add send_channel_event method on socket for client channel events

0.4.0 and previous not documented :/

