open Hidapi

let () =
  init () ;
  let devs = Hidapi.enumerate () in
  ListLabels.iter devs ~f:begin fun ({ vendor_id ; product_id } as d) ->
    Printf.printf "%s\n"
      (Sexplib.Sexp.to_string_hum (Hidapi.sexp_of_device_info d)) ;
    match open_id ~vendor_id ~product_id with
    | None ->
      Printf.printf "Impossible to open %d:%d\n" vendor_id product_id
    | Some d ->
      close d ;
      Printf.printf "Ok, opened/closed %d:%d\n" vendor_id product_id ;
  end ;
  deinit ()
