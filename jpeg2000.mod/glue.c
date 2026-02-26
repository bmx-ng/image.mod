/*
 Copyright (c) 2023 Bruce A Henderson

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 1. Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
*/
#include "brl.mod/blitz.mod/blitz.h"
#include "openjpeg.h"

size_t image_jpeg2000_TJpeg2000Image__stream_read(void * p_buffer, size_t p_nb_bytes, void * p_user_data);
int image_jpeg2000_TJpeg2000Image__stream_seek(BBLONG p_nb_bytes, void * p_user_data);
BBLONG image_jpeg2000_TJpeg2000Image__stream_skip(BBLONG p_nb_bytes, void * p_user_data);
size_t image_jpeg2000_TJpeg2000Image__stream_size(void * p_user_data);
BBObject * image_jpeg2000_TJpeg2000Image__NewPixmap(int width, int height);
void * image_jpeg2000_TJpeg2000Image__PixmapPixels(BBObject * pixmap);

static inline OPJ_SIZE_T bmx_stream_read(void * p_buffer, OPJ_SIZE_T p_nb_bytes, void * p_user_data) {
    return image_jpeg2000_TJpeg2000Image__stream_read(p_buffer, p_nb_bytes, p_user_data);
}

static inline OPJ_BOOL bmx_stream_seek(OPJ_OFF_T p_nb_bytes, void * p_user_data) {
    return image_jpeg2000_TJpeg2000Image__stream_seek((BBLONG)p_nb_bytes, p_user_data);
}

static inline OPJ_OFF_T bmx_stream_skip(OPJ_OFF_T p_nb_bytes, void * p_user_data) {
    return (OPJ_OFF_T)image_jpeg2000_TJpeg2000Image__stream_skip((BBLONG)p_nb_bytes, p_user_data);
}

BBObject * bmx_jpeg2000_load( BBObject * maxStream ) {

    opj_dparameters_t parameters;
    opj_image_t* image = NULL;

    opj_set_default_decoder_parameters(&parameters);


    opj_stream_t* stream = opj_stream_create(8192, OPJ_TRUE);

    if (!stream) {
        return &bbNullObject;
    }

    opj_stream_set_user_data(stream, maxStream, NULL);
    opj_stream_set_user_data_length(stream, image_jpeg2000_TJpeg2000Image__stream_size(maxStream));
    opj_stream_set_read_function(stream, bmx_stream_read);
    opj_stream_set_seek_function(stream, bmx_stream_seek);
    opj_stream_set_skip_function(stream, bmx_stream_skip);

    opj_codec_t* codec = opj_create_decompress(OPJ_CODEC_JP2);

    if (!opj_setup_decoder(codec, &parameters)) {
        opj_stream_destroy(stream);
        opj_destroy_codec(codec);

        return &bbNullObject;
    }

    if (!opj_read_header(stream, codec, &image)) {
        opj_stream_destroy(stream);
        opj_destroy_codec(codec);
        
        return &bbNullObject;
    }

    if (!opj_decode(codec, stream, image)) {
        opj_stream_destroy(stream);
        opj_destroy_codec(codec);

        return &bbNullObject;
    }

    int width = image->comps[0].w;
    int height = image->comps[0].h;
    int num_components = image->numcomps;

    // create a TPixmap
    BBObject * pixmap = image_jpeg2000_TJpeg2000Image__NewPixmap(width, height);

    // get the pixel data
    void * pixels = image_jpeg2000_TJpeg2000Image__PixmapPixels(pixmap);

    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {

            // pixel index
            int index = y * width + x;

            // colour components
            uint32_t r = image->comps[0].data[index];
            uint32_t g = image->comps[1].data[index];
            uint32_t b = image->comps[2].data[index];
            uint32_t a = image->numcomps > 3 ? image->comps[3].data[index] : 255;  // assuming alpha if it exists

            // Convert the components
            uint32_t rgba = (a << 24) | (b << 16) | (g << 8) | r;

            // Set the pixel in the pixmap
            ((uint32_t*)pixels)[index] = rgba;
        }
    }

    opj_image_destroy(image);
    opj_stream_destroy(stream);
    opj_destroy_codec(codec);

    return pixmap;
}
