(*---------------------------------------------------------------------------
   Copyright (c) 2017 Vincent Bernardoff. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
  ---------------------------------------------------------------------------*)

type device_info = {
  path : string ;
  vendor_id : int ;
  product_id : int ;
  serial_number : string ;
  release_number : int ;
  manufacturer_string : string ;
  product_string : string ;
  usage_page : int ;
  usage : int ;
  interface_number : int ;
} [@@deriving sexp]

type hid_device

val hid_init : unit -> unit
val hid_exit : unit -> unit
val hid_enumerate : ?vendor_id:int -> ?product_id:int -> unit -> device_info list
val hid_open : vendor_id:int -> product_id:int -> hid_device
val hid_open_path : string -> hid_device
val hid_write : hid_device -> Cstruct.t -> int
val hid_read : ?timeout:int -> hid_device -> Cstruct.t -> int -> int
val hid_set_nonblocking : hid_device -> bool -> unit
val hid_close : hid_device -> unit

(*---------------------------------------------------------------------------
   Copyright (c) 2017 Vincent Bernardoff

   Permission to use, copy, modify, and/or distribute this software for any
   purpose with or without fee is hereby granted, provided that the above
   copyright notice and this permission notice appear in all copies.

   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
   WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
   MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
   ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
   WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
   ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
   OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
  ---------------------------------------------------------------------------*)
