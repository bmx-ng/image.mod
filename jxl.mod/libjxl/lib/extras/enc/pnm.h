// Copyright (c) the JPEG XL Project Authors. All rights reserved.
//
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#ifndef LIB_EXTRAS_ENC_PNM_H_
#define LIB_EXTRAS_ENC_PNM_H_

// Encodes/decodes PBM/PGM/PPM/PFM pixels in memory.

// TODO(janwas): workaround for incorrect Win64 codegen (cause unknown)
#include <hwy/highway.h>

#include "lib/extras/enc/encode.h"
#include "lib/extras/packed_image.h"
#include "lib/jxl/base/data_parallel.h"
#include "lib/jxl/base/padded_bytes.h"
#include "lib/jxl/base/status.h"
#include "lib/jxl/codec_in_out.h"
#include "lib/jxl/color_encoding_internal.h"

namespace jxl {
namespace extras {

std::unique_ptr<Encoder> GetPGMEncoder();
std::unique_ptr<Encoder> GetPPMEncoder();
std::unique_ptr<Encoder> GetPFMEncoder();

// Transforms from io->c_current to `c_desired` and encodes into `bytes`.
Status EncodeImagePNM(const PackedPixelFile& ppf, size_t bits_per_sample,
                      ThreadPool* pool, size_t frame_index,
                      std::vector<uint8_t>* bytes);

}  // namespace extras
}  // namespace jxl

#endif  // LIB_EXTRAS_ENC_PNM_H_
