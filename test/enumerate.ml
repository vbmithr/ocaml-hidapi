let () =
  let devs = Hidapi.hid_enumerate () in
  List.iter begin fun d ->
    Printf.printf "%s\n%!"
      (Sexplib.Sexp.to_string_hum (Hidapi.sexp_of_device_info d))
  end devs
