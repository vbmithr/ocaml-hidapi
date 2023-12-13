(*---------------------------------------------------------------------------
   Copyright (c) 2023 Vincent Bernardoff. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
  ---------------------------------------------------------------------------*)

open Lwt.Syntax

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

type info

external hid_enumerate : int -> int -> info option Lwt_unix.job
  = "hid_enumerate_job"

external hid_enumerate_next : info -> Hidapi.device_info * info option
  = "stub_hid_enumerate_next"

external hid_free_enumeration : info -> unit = "stub_hid_free_enumeration"
  [@@noalloc]

external hid_open_job : int -> int -> Hidapi.t option Lwt_unix.job
  = "hid_open_job"

external hid_open_path_job : string -> Hidapi.t option Lwt_unix.job
  = "hid_open_path_job"

external hid_close_job : Hidapi.t -> unit Lwt_unix.job = "hid_close_job"

external hid_read_timeout_job :
  Hidapi.t -> Bigstring.t -> int -> int -> int Lwt_unix.job
  = "hid_read_timeout_job"

external hid_write_job : Hidapi.t -> Bigstring.t -> int -> int Lwt_unix.job
  = "hid_write_job"

external hid_error : Hidapi.t -> string option = "stub_hid_error"

let init = Hidapi.init

let deinit = Hidapi.deinit

let enumerate ?(vendor_id = 0) ?(product_id = 0) () =
  let* result = Lwt_unix.run_job (hid_enumerate vendor_id product_id) in
  match result with
  | None -> Lwt.return_nil
  | Some info ->
      let rec inner acc i =
        match hid_enumerate_next i with
        | di, None -> di :: acc
        | di, Some next -> inner (di :: acc) next
      in
      let res = inner [] info in
      hid_free_enumeration info ;
      Lwt.return res

let open_id ~vendor_id ~product_id =
  Lwt_unix.run_job (hid_open_job vendor_id product_id)

let open_id_exn ~vendor_id ~product_id =
  let* result = open_id ~vendor_id ~product_id in
  match result with None -> failwith "open_id_exn" | Some t -> Lwt.return t

let open_path path = Lwt_unix.run_job (hid_open_path_job path)

let open_path_exn path =
  let* result = open_path path in
  match result with None -> failwith "open_path_exn" | Some t -> Lwt.return t

let close t = Lwt_unix.run_job (hid_close_job t)

let write t ?len buf =
  let buflen = Bigstring.length buf in
  let* len =
    match len with
    | None -> Lwt.return buflen
    | Some l when l < 0 ->
        Lwt.fail_invalid_arg
          (Printf.sprintf "write: len = %d must be positive" l)
    | Some l when l > buflen ->
        Lwt.fail_invalid_arg
          (Printf.sprintf "write: len is too big (%d > %d)" l buflen)
    | Some l -> Lwt.return l
  in
  let* result = Lwt_unix.run_job (hid_write_job t buf len) in
  match result with
  | -1 ->
      Lwt.return_error (match hid_error t with None -> "" | Some msg -> msg)
  | nb_written -> Lwt.return_ok nb_written

let read ?(timeout = -1) t buf len =
  let* result = Lwt_unix.run_job (hid_read_timeout_job t buf len timeout) in
  match result with
  | -1 ->
      Lwt.return_error (match hid_error t with None -> "" | Some msg -> msg)
  | nb_read -> Lwt.return_ok nb_read

let set_nonblocking = Hidapi.set_nonblocking

let set_nonblocking_exn = Hidapi.set_nonblocking_exn

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
