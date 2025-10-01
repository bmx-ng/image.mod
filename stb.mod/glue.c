/*
  Copyright (c) 2022-2024 Bruce A Henderson
  
  This software is provided 'as-is', without any express or implied
  warranty. In no event will the authors be held liable for any damages
  arising from the use of this software.
  
  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:
  
  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.
*/
#define STB_IMAGE_IMPLEMENTATION

#define STBI_NO_STDIO
#define STBI_ONLY_GIF
#define STBI_ONLY_PIC
#define STBI_ONLY_PNM

#include "stb/stb_image.h"

#include "brl.mod/blitz.mod/blitz.h"


extern int image_stb_TStbioCallbacks__Read(BBObject * cb, char * data,int size);
extern void image_stb_TStbioCallbacks__Skip(BBObject * cb, int n);
extern int image_stb_TStbioCallbacks__Eof(BBObject * cb);

stbi_uc *bmx_stbi_load_gif_from_callbacks(stbi_io_callbacks const *clbk, void *user, int **delays, int *x, int *y, int *z, int *comp, int req_comp);

stbi_uc * bmx_stbi_load_image(BBObject * cb, int * width, int * height, int * channels) {

	stbi_io_callbacks callbacks;
	callbacks.read = (int (*)(void *, char *, int))image_stb_TStbioCallbacks__Read;
	callbacks.skip = (void (*)(void *, int))image_stb_TStbioCallbacks__Skip;
	callbacks.eof = (int (*)(void *))image_stb_TStbioCallbacks__Eof;

	return stbi_load_from_callbacks(&callbacks, cb, width, height, channels, 0);
}

stbi_uc * bmx_stbi_load_gif(BBObject * cb, int **delays, int *x, int *y, int *z, int *comp, int req_comp) {

	stbi_io_callbacks callbacks;
	callbacks.read = (int (*)(void *, char *, int))image_stb_TStbioCallbacks__Read;
	callbacks.skip = (void (*)(void *, int))image_stb_TStbioCallbacks__Skip;
	callbacks.eof = (int (*)(void *))image_stb_TStbioCallbacks__Eof;

	return bmx_stbi_load_gif_from_callbacks(&callbacks, cb, delays, x, y, z, comp, req_comp);
}

void bmx_stbi_free_delays(int ** delays) {
   if (delays && *delays) STBI_FREE(*delays);
}

stbi_uc * bmx_stbi_load_gif_from_callbacks(stbi_io_callbacks const *clbk, void *user, int **delays, int *x, int *y, int *z, int *comp, int req_comp)
{
   unsigned char *result;
   stbi__context s;
   stbi__start_callbacks(&s, (stbi_io_callbacks *) clbk, user);
   result = (unsigned char*) stbi__load_gif_main(&s, delays, x, y, z, comp, req_comp);
   if (stbi__vertically_flip_on_load) {
      stbi__vertical_flip_slices( result, *x, *y, *z, *comp );
   }
   return result;
}
