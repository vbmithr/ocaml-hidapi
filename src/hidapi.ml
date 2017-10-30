open Sexplib.Std

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

external hid_init : unit -> unit = "ml_hid_init" [@@noalloc]
external hid_exit : unit -> unit = "ml_hid_exit" [@@noalloc]
external hid_enumerate : int -> int -> device_info list = "ml_hid_enumerate"
external hid_open : int -> int -> hid_device = "ml_hid_open" [@@noalloc]
external hid_open_path : string -> hid_device = "ml_hid_open_path" [@@noalloc]
external hid_write : hid_device -> Cstruct.buffer -> int -> int = "ml_hid_write" [@@noalloc]
external hid_read_timeout : hid_device -> Cstruct.buffer -> int -> int -> int = "ml_hid_read_timeout" [@@noalloc]
external hid_read : hid_device -> Cstruct.buffer -> int -> int = "ml_hid_read" [@@noalloc]
external hid_set_nonblocking : hid_device -> bool -> unit = "ml_hid_set_nonblocking" [@@noalloc]
external hid_close : hid_device -> unit = "ml_hid_close" [@@noalloc]

let hid_enumerate ?(vendor_id=0) ?(product_id=0) () =
  hid_enumerate vendor_id product_id

let hid_open ~vendor_id ~product_id =
  hid_open vendor_id product_id

let hid_write dev buf = hid_write dev (Cstruct.to_bigarray buf) (Cstruct.len buf)

let hid_read ?(timeout=(-1)) dev buf len =
  hid_read_timeout dev (Cstruct.to_bigarray buf) len timeout
