#include <stdio.h>
#include <hidapi/hidapi.h>

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/fail.h>
#include <caml/bigarray.h>

char buf[1024];

const char* get_hid_error(hid_device *dev) {
    const wchar_t *err_string;
    size_t ret;
    err_string = hid_error(dev);

    if (err_string == NULL)
        return NULL;

    snprintf(buf, sizeof(buf), "%ls", err_string);
    return buf;
}

CAMLprim value copy_device_info (struct hid_device_info *di) {
    CAMLparam0();
    CAMLlocal1(result);
    result = caml_alloc_tuple(10);


    Store_field(result, 0, caml_copy_string(di->path));
    Store_field(result, 1, Val_int(di->vendor_id));
    Store_field(result, 2, Val_int(di->product_id));
    snprintf(buf, sizeof(buf), "%ls", di->serial_number);
    Store_field(result, 3, caml_copy_string(buf));
    Store_field(result, 4, Val_int(di->release_number));
    snprintf(buf, sizeof(buf), "%ls", di->manufacturer_string);
    Store_field(result, 5, caml_copy_string(buf));
    snprintf(buf, sizeof(buf), "%ls", di->product_string);
    Store_field(result, 6, caml_copy_string(buf));
    Store_field(result, 7, Val_int(di->usage_page));
    Store_field(result, 8, Val_int(di->usage));
    Store_field(result, 9, Val_int(di->interface_number));

    CAMLreturn(result);
}

CAMLprim value ml_hid_init(void) {
    CAMLparam0();
    int ret = hid_init();
    if (ret == -1)
        caml_failwith("ml_hid_init");

    CAMLreturn(Val_unit);
}

CAMLprim value ml_hid_exit(void) {
    CAMLparam0();
    int ret = hid_exit();
    if (ret == -1)
        caml_failwith("ml_hid_exit");

    CAMLreturn(Val_unit);
}

CAMLprim value ml_hid_enumerate(value vendor_id, value product_id) {
    CAMLparam2(vendor_id, product_id);
    CAMLlocal2(result, tmp);

    tmp = Val_int(0);
    result = Val_int(0);

    struct hid_device_info *di = hid_enumerate(Int_val(vendor_id), Int_val(product_id));
    struct hid_device_info *cur = di;

    while(cur != NULL) {
        result = caml_alloc_tuple(2);
        Store_field(result, 0, copy_device_info(cur));
        Store_field(result, 1, tmp);
        tmp = result;
        cur = cur->next;
    }

    hid_free_enumeration(di);
    CAMLreturn(result);
}

CAMLprim value ml_hid_open(value vendor_id, value product_id) {
    CAMLparam2(vendor_id, product_id);
    hid_device* h = hid_open(Int_val(vendor_id), Int_val(product_id), NULL);
    if (h == NULL)
        caml_failwith("ml_hid_open");

    CAMLreturn((value)h);
}

CAMLprim value ml_hid_open_path(value path) {
    CAMLparam1(path);
    hid_device* h = hid_open_path(String_val(path));
    if (h == NULL)
        caml_failwith("ml_hid_open");

    CAMLreturn((value)h);
}

CAMLprim value ml_hid_write(value dev, value data, value len) {
    CAMLparam3(dev, data, len);
    int nb_written;
    nb_written = hid_write((hid_device *)dev, Caml_ba_data_val(data), Int_val(len));
    if (nb_written == -1)
        caml_failwith(get_hid_error((hid_device *)dev));

    CAMLreturn(Val_int(nb_written));
}

CAMLprim value ml_hid_read_timeout(value dev, value data, value len, value ms) {
    CAMLparam4(dev, data, len, ms);
    int nb_read;
    nb_read = hid_read_timeout((hid_device *)dev, Caml_ba_data_val(data), Int_val(len), Int_val(ms));
    if (nb_read == -1)
        caml_failwith(get_hid_error((hid_device *)dev));

    CAMLreturn(Val_int(nb_read));
}

CAMLprim value ml_hid_read(value dev, value data, value len) {
    CAMLparam3(dev, data, len);
    int nb_read;
    nb_read = hid_read((hid_device *)dev, Caml_ba_data_val(data), Int_val(len));
    if (nb_read == -1)
        caml_failwith(get_hid_error((hid_device *)dev));

    CAMLreturn(Val_int(nb_read));
}

CAMLprim value ml_hid_set_nonblocking(value dev, value nonblock) {
    CAMLparam2(dev, nonblock);
    int ret;
    ret = hid_set_nonblocking((hid_device *)dev, Bool_val(nonblock));
    if (ret == -1)
        caml_failwith(get_hid_error((hid_device *)dev));

    CAMLreturn(Val_unit);
}

CAMLprim value ml_hid_close(value dev) {
    CAMLparam1(dev);
    hid_close((hid_device *)dev);
    CAMLreturn(Val_unit);
}



