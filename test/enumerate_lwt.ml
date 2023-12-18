open Lwt.Syntax
open Lwt.Infix

let main =
  Hidapi_lwt.init () ;
  let* devs = Hidapi_lwt.enumerate () in
  let* () = Lwt_list.iter_s
      begin fun Hidapi.{ path; vendor_id; product_id;
                         serial_number; release_number;
                         manufacturer_string; product_string;
                         interface_number ; _ } ->
        let s = match serial_number with None -> "" | Some s -> s in
        let m = match manufacturer_string with None -> "" | Some s -> s in
        let p = match product_string with None -> "" | Some s -> s in
        let* () = Lwt_io.printlf "%s 0x%04x 0x%04x %s %d %s %s %d"
            path vendor_id product_id
            s release_number m p
            interface_number in
        Hidapi_lwt.open_id ~vendor_id ~product_id >>= function
        | None ->
          Lwt_io.printlf "Impossible to open %d:%d" vendor_id product_id
        | Some d ->
          let* () = Hidapi_lwt.close d in
          Lwt_io.printlf "Ok, opened/closed %d:%d" vendor_id product_id
      end
      devs in
  Hidapi_lwt.deinit ();
  Lwt.return_unit

let () = Lwt_main.run main
