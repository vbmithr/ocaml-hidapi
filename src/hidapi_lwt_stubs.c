/* --------------------------------------------------------------------------
   Copyright (c) 2023 Vincent Bernardoff. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   --------------------------------------------------------------------------- */

#include <stdio.h>
#include <hidapi.h>

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/bigarray.h>
#include <lwt_config.h>
#include <lwt_unix.h>

typedef struct hid_device_info hid_device_info_t;

#define Hid_val(v) (*((hid_device **) Data_custom_val(v)))
#define Hidinfo_val(v) (*((hid_device_info_t **) Data_custom_val(v)))

#define Gen_custom_block(SNAME, CNAME, MNAME)                           \
    static int compare_##SNAME(value a, value b) {                      \
        CNAME *aa = MNAME(a), *bb = MNAME(b);                           \
        return (aa == bb ? 0 : (aa < bb ? -1 : 1));                     \
    }                                                                   \
                                                                        \
    static struct custom_operations hidapi_##SNAME##_ops = {		\
        .identifier = "hidapi_" #SNAME,					\
        .finalize = custom_finalize_default,                            \
        .compare = compare_##SNAME,                                     \
        .compare_ext = custom_compare_ext_default,                      \
        .hash = custom_hash_default,                                    \
        .serialize = custom_serialize_default,                          \
        .deserialize = custom_deserialize_default                       \
    };                                                                  \
                                                                        \
    static value alloc_##SNAME (CNAME *a) {                             \
        value custom = caml_alloc_custom(&hidapi_##SNAME##_ops, sizeof(CNAME *), 0, 1); \
        MNAME(custom) = a;                                              \
        return custom;                                                  \
    }

Gen_custom_block(hid, hid_device, Hid_val)
Gen_custom_block(hidinfo, hid_device_info_t, Hidinfo_val)

#if !defined(LWT_ON_WINDOWS)

struct job_hid_enumerate {
  struct lwt_unix_job job;
  unsigned short vendor_id;
  unsigned short product_id;
  hid_device_info_t *result;
  int error_code;
};

static void worker_hid_enumerate(struct job_hid_enumerate *job) {
  job->result = hid_enumerate(job->vendor_id, job->product_id);
}

static value result_hid_enumerate(struct job_hid_enumerate *job)
{
  value result;
  if (job->result == NULL)
    result = Val_unit;
  else {
    result = caml_alloc(1, 0);
    value hidinfo = alloc_hidinfo(job->result);
    Store_field(result, 0, hidinfo);
  }
  lwt_unix_free_job(&job->job);
  return result;
}

CAMLprim value hid_enumerate_job(value mlvendor_id, value mlproduct_id)
{
  unsigned short vendor_id = Int_val(mlvendor_id);
  unsigned short product_id = Int_val(mlproduct_id);
  LWT_UNIX_INIT_JOB(job, hid_enumerate, 0);
  job->vendor_id = vendor_id;
  job->product_id = product_id;
  return lwt_unix_alloc_job(&(job->job));
}

struct job_hid_open {
  struct lwt_unix_job job;
  unsigned short vendor_id;
  unsigned short product_id;
  hid_device *result;
  int error_code;
};

static void worker_hid_open(struct job_hid_open *job) {
  job->result = hid_open(job->vendor_id, job->product_id, NULL);
}

static value result_hid_open(struct job_hid_open *job)
{
  value result;
  if (job->result == NULL)
    result = Val_unit;
  else {
    result = caml_alloc(1, 0);
    value hid = alloc_hid(job->result);
    Store_field(result, 0, hid);
  }
  lwt_unix_free_job(&job->job);
  return result;
}

CAMLprim value hid_open_job(value mlvendor_id, value mlproduct_id)
{
  unsigned short vendor_id = Int_val(mlvendor_id);
  unsigned short product_id = Int_val(mlproduct_id);
  LWT_UNIX_INIT_JOB(job, hid_open, 0);
  job->vendor_id = vendor_id;
  job->product_id = product_id;
  return lwt_unix_alloc_job(&(job->job));
}

struct job_hid_open_path {
  struct lwt_unix_job job;
  const char *path;
  hid_device *result;
  int error_code;
};

static void worker_hid_open_path(struct job_hid_open_path *job) {
  job->result = hid_open_path(job->path);
}

static value result_hid_open_path(struct job_hid_open_path *job)
{
  value result;
  if (job->result == NULL)
    result = Val_unit;
  else {
    result = caml_alloc(1, 0);
    value hid = alloc_hid(job->result);
    Store_field(result, 0, hid);
  }
  lwt_unix_free_job(&job->job);
  return result;
}

CAMLprim value hid_open_path_job(value mlpath)
{
  const char *path = String_val(mlpath);
  LWT_UNIX_INIT_JOB(job, hid_open_path, 0);
  job->path = path;
  return lwt_unix_alloc_job(&(job->job));
}

struct job_hid_close {
  struct lwt_unix_job job;
  hid_device *dev;
  int error_code;
};

static void worker_hid_close(struct job_hid_close *job) {
  hid_close(job->dev);
}

static value result_hid_close(struct job_hid_close *job)
{
  lwt_unix_free_job(&job->job);
  return Val_unit;
}

CAMLprim value hid_close_job(value mldev)
{
  hid_device *dev = Hid_val(mldev);
  LWT_UNIX_INIT_JOB(job, hid_close, 0);
  job->dev = dev;
  return lwt_unix_alloc_job(&(job->job));
}

struct job_hid_read_timeout {
  struct lwt_unix_job job;
  /* The file descriptor. */
  hid_device *dev;
  value data;
  int milliseconds;
  long length;
  long result;
  int error_code;
  char buffer[];
};

static void worker_hid_read_timeout(struct job_hid_read_timeout *job) {
  job->result = hid_read_timeout(job->dev, job->buffer, job->length, job->milliseconds);
}

static value result_hid_read_timeout(struct job_hid_read_timeout *job)
{
  long result = job->result;
  LWT_UNIX_CHECK_JOB(job, result < 0, "hid_read_timeout");
  memcpy(Caml_ba_data_val(job->data), job->buffer, result);
  lwt_unix_free_job(&job->job);
  return Val_long(result);
}

CAMLprim value hid_read_timeout_job(value mldev, value mldata, value mllen, value mlms)
{
  long length = Long_val(mllen);
  hid_device *dev = Hid_val(mldev);
  int milliseconds = Long_val(mlms);
  LWT_UNIX_INIT_JOB(job, hid_read_timeout, length);
  job->dev = dev;
  job->length = length;
  job->milliseconds = milliseconds;
  job->data = mldata;
  return lwt_unix_alloc_job(&(job->job));
}

struct job_hid_write {
  struct lwt_unix_job job;
  /* The file descriptor. */
  hid_device *dev;
  long length;
  long result;
  int error_code;
  char buffer[];
};

static void worker_hid_write(struct job_hid_write *job) {
  job->result = hid_write(job->dev, job->buffer, job->length);
}

static value result_hid_write(struct job_hid_write *job)
{
  long result = job->result;
  LWT_UNIX_CHECK_JOB(job, result < 0, "hid_write");
  lwt_unix_free_job(&job->job);
  return Val_long(result);
}

CAMLprim value hid_write_job(value mldev, value mldata, value mllength)
{
  long length = Long_val(mllength);
  hid_device *dev = Hid_val(mldev);
  void *data = Caml_ba_data_val(mldata);
  LWT_UNIX_INIT_JOB(job, hid_write, length);
  job->dev = dev;
  job->length = length;
  memcpy(job->buffer, data, length);
  return lwt_unix_alloc_job(&(job->job));
}

#endif

/* --------------------------------------------------------------------------
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
   --------------------------------------------------------------------------- */
