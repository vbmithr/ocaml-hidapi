(*---------------------------------------------------------------------------
   Copyright (c) 2023 Vincent Bernardoff. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
  ---------------------------------------------------------------------------*)

type device_info = Hidapi.device_info = {
  path : string;
  vendor_id : int;
  product_id : int;
  serial_number : string option;
  release_number : int;
  manufacturer_string : string option;
  product_string : string option;
  usage_page : int;
  usage : int;
  interface_number : int;
}

type t = Hidapi.t

val init : unit -> unit

val deinit : unit -> unit

val enumerate :
  ?vendor_id:int -> ?product_id:int -> unit -> Hidapi.device_info list Lwt.t

val open_id : vendor_id:int -> product_id:int -> Hidapi.t option Lwt.t

val open_path : string -> Hidapi.t option Lwt.t

val open_id_exn : vendor_id:int -> product_id:int -> Hidapi.t Lwt.t

val open_path_exn : string -> Hidapi.t Lwt.t

val write : Hidapi.t -> ?len:int -> Bigstring.t -> (int, string) result Lwt.t

val read :
  ?timeout:int -> Hidapi.t -> Bigstring.t -> int -> (int, string) result Lwt.t

val set_nonblocking : t -> bool -> (unit, string) result

val set_nonblocking_exn : t -> bool -> unit

val close : Hidapi.t -> unit Lwt.t

(*---------------------------------------------------------------------------
   Copyright (c) 2023 Vincent Bernardoff

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
