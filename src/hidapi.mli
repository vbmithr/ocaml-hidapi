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
type buffer = (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t

val hid_init : unit -> unit
val hid_exit : unit -> unit
val hid_enumerate : ?vendor_id:int -> ?product_id:int -> unit -> device_info list
val hid_open : vendor_id:int -> product_id:int -> hid_device
val hid_open_path : string -> hid_device
val hid_write : hid_device -> buffer -> int -> int
val hid_read_blocking : hid_device -> buffer -> int -> int
val hid_read_timeout : timeout:int -> hid_device -> buffer -> int -> int
val hid_set_nonblocking : hid_device -> bool -> unit
val hid_close : hid_device -> unit
