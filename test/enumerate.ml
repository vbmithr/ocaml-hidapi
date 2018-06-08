open Hidapi

let () =
  init () ;
  let devs = Hidapi.enumerate () in
  ListLabels.iter devs ~f:begin fun { path; vendor_id; product_id;
                                      serial_number; release_number;
                                      manufacturer_string; product_string;
                                      usage_page; usage; interface_number } ->
    Printf.printf "%s 0x%04x 0x%04x %s %d %s %s %d\n"
      path vendor_id product_id
      serial_number release_number
      manufacturer_string product_string
      interface_number ;
    match open_id ~vendor_id ~product_id with
    | None ->
      Printf.printf "Impossible to open %d:%d\n" vendor_id product_id
    | Some d ->
      close d ;
      Printf.printf "Ok, opened/closed %d:%d\n" vendor_id product_id ;
  end ;
  deinit ()
