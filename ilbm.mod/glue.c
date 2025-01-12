/*
  Copyright (c) 2022-2025 Bruce A Henderson
 
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:
  
  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.
  
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.
*/ 
#include "libilbm/ilbm.h"
#include "libilbm/ilbmimage.h"
#include "libamivideo/screen.h"
#include "libamivideo/viewportmode.h"
#include "image.h"

#include "brl.mod/blitz.mod/blitz.h"

extern int image_ilbm_TIlbmIoCallbacks__Read(void * cb, char * data,int size);
extern int image_ilbm_TIlbmIoCallbacks__Write(void * cb, char * data,int size);
extern int image_ilbm_TIlbmIoCallbacks__Eof(void * cb);

IFF_Chunk * bmx_ilbm_load_iff(BBObject * cb) {

	io_callbacks callbacks;
	callbacks.read = image_ilbm_TIlbmIoCallbacks__Read;
	callbacks.write = image_ilbm_TIlbmIoCallbacks__Write;
	callbacks.eof = image_ilbm_TIlbmIoCallbacks__Eof;

    io_context context;
    context.userData = cb;
    context.io = callbacks;

	return ILBM_readIo(&context);
}

ilbm_image_out * bmx_ilbm_get_image(ILBM_Image * ilbmImage, unsigned int pixelScaleFactor) {
    amiVideo_Screen screen;

    SDL_ILBM_initScreenFromImage(ilbmImage, &screen);

    if (pixelScaleFactor == 0) {
        pixelScaleFactor = amiVideo_autoSelectLowresPixelScaleFactor(screen.viewportMode);
    }

    ilbm_image_out * image = SDL_ILBM_generateSurfaceFromScreen(ilbmImage, &screen, SDL_ILBM_FORMAT_RGB, pixelScaleFactor);

    amiVideo_cleanupScreen(&screen);
 
    return image;
}
