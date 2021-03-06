/**
 * Slighty adapted by Roman Hiestand, 2014 (removed references to SDL).
 *
 * Originally, this file is part of SDL_ILBM, see:
 * https://github.com/svanderburg/SDL_ILBM
 */

/*
 * Copyright (c) 2012 Sander van der Burg
 *
 * This software is provided 'as-is', without any express or implied warranty.
 * In no event will the authors be held liable for any damages arising from
 * the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 * 1. The origin of this software must not be misrepresented; you must not
 * claim that you wrote the original software. If you use this software in a
 * product, an acknowledgment in the product documentation would be
 * appreciated but is not required.
 *
 * 2. Altered source versions must be plainly marked as such, and must not be
 * misrepresented as being the original software.
 *
 * 3. This notice may not be removed or altered from any source distribution.
 *
 * Sander van der Burg <svanderburg@gmail.com>
 */

#include <stdlib.h>
#include <string.h>

#include "image.h"
#include <libilbm/ilbmimage.h>
#include <libilbm/interleave.h>
#include <libilbm/byterun.h>
#include <libamivideo/viewportmode.h>

void SDL_ILBM_initPaletteFromImage(const ILBM_Image *image, amiVideo_Palette *palette)
{
    if(image->colorMap == NULL)
    {
        /* If no colormap is provided by the image, use a generated grayscale one */
        ILBM_ColorMap *colorMap = ILBM_generateGrayscaleColorMap(image);
        amiVideo_setBitplanePaletteColors(palette, (amiVideo_Color*)colorMap->colorRegister, colorMap->colorRegisterLength);
        free(colorMap);
    }
    else
        amiVideo_setBitplanePaletteColors(palette, (amiVideo_Color*)image->colorMap->colorRegister, image->colorMap->colorRegisterLength);
}

amiVideo_ULong SDL_ILBM_extractViewportModeFromImage(const ILBM_Image *image)
{
    amiVideo_ULong paletteFlags, resolutionFlags;
    
    if(image->viewport == NULL)
        paletteFlags = 0; /* If no viewport value is set, assume 0 value */
    else
        paletteFlags = amiVideo_extractPaletteFlags(image->viewport->viewportMode); /* Only the palette flags can be considered "reliable" from a viewport mode value */
        
    /* Resolution flags are determined by looking at the page dimensions */
    resolutionFlags = amiVideo_autoSelectViewportMode(image->bitMapHeader->pageWidth, image->bitMapHeader->pageHeight);
    
    /* Return the combined settings of the previous */
    return paletteFlags | resolutionFlags;
}

void SDL_ILBM_initScreenFromImage(ILBM_Image *image, amiVideo_Screen *screen)
{
    /* Determine which viewport mode is best for displaying the image */
    IFF_Long viewportMode = SDL_ILBM_extractViewportModeFromImage(image);

	/* Initialise screen width the image's dimensions, bitplane depth, and viewport mode */
	amiVideo_initScreen(screen, image->bitMapHeader->w, image->bitMapHeader->h, image->bitMapHeader->nPlanes, 8, viewportMode);

	/* Sets the colors of the palette */
	SDL_ILBM_initPaletteFromImage(image, &screen->palette);

	/* Decompress the image body */
	ILBM_unpackByteRun(image);

	if(ILBM_imageIsPBM(image))
		amiVideo_setScreenUncorrectedChunkyPixelsPointer(screen, (amiVideo_UByte*)image->body->chunkData, image->bitMapHeader->w); /* A PBM has chunky pixels in its body */
    else if(ILBM_imageIsACBM(image))
        amiVideo_setScreenBitplanes(screen, (amiVideo_UByte*)image->bitplanes->chunkData); /* Set bitplane pointers of the conversion screen */
    else if(ILBM_imageIsILBM(image))
	{
        if(ILBM_convertILBMToACBM(image)) /* Amiga ILBM image has interleaved scanlines per bitplane. We have to deinterleave it in order to be able to convert it */
            amiVideo_setScreenBitplanes(screen, (amiVideo_UByte*)image->bitplanes->chunkData); /* Set bitplane pointers of the conversion screen */
	}
}

int SDL_ILBM_setPalette(ilbm_image_out *img_out, amiVideo_Palette *palette)
{
	unsigned int i;
	unsigned char *pal_out;

	img_out->colorsCount = palette->chunkyFormat.numOfColors;
	img_out->palette = (unsigned char *)malloc(palette->chunkyFormat.numOfColors * 3 * sizeof(unsigned char));
	pal_out = img_out->palette;
	for(i = 0; i < img_out->colorsCount; i++)
	{
		*(pal_out++) = palette->chunkyFormat.color[i].r;
		*(pal_out++) = palette->chunkyFormat.color[i].g;
		*(pal_out++) = palette->chunkyFormat.color[i].b;
	}

	return TRUE;
}

int SDL_ILBM_convertScreenPixelsToSurfacePixels(const ILBM_Image *image, ilbm_image_out *img_out,
	amiVideo_Screen *screen, const SDL_ILBM_Format format, const unsigned int lowresPixelScaleFactor)
{
    IFF_RawChunk *pixelChunk;
    
    if(ILBM_imageIsACBM(image))
        pixelChunk = image->bitplanes;
    else
        pixelChunk = image->body;

	if(lowresPixelScaleFactor == 1)
	{
		if(format == SDL_ILBM_FORMAT_CHUNKY)
		{
			/* Convert the colors of the the bitplane palette to the format of the chunky palette */
			amiVideo_convertBitplaneColorsToChunkyFormat(&screen->palette);

			/* Set the palette of the target SDL surface */
			if(!SDL_ILBM_setPalette(img_out, &screen->palette))
				return FALSE;

			if(pixelChunk != NULL)
			{
				/* Populate the surface with pixels in chunky format */

				if(ILBM_imageIsPBM(image))
					memcpy(screen->uncorrectedChunkyFormat.pixels, image->body->chunkData, image->body->chunkSize);
				else
					amiVideo_convertScreenBitplanesToChunkyPixels(screen); /* Convert the bitplanes to chunky pixels */

			}
		}
		else
		{
			if(pixelChunk != NULL)
			{
				/* Populate the surface with pixels in RGB format */

				if(ILBM_imageIsPBM(image))
				{
                    if(screen->bitplaneDepth == 24 || screen->bitplaneDepth == 32)
                    {
                        memcpy(screen->uncorrectedRGBFormat.pixels, pixelChunk->chunkData, pixelChunk->chunkSize);
                        amiVideo_reorderRGBPixels(screen);
                    }
                    else
                    {
					    amiVideo_convertBitplaneColorsToChunkyFormat(&screen->palette);
					    amiVideo_convertScreenChunkyPixelsToRGBPixels(screen);
				    }
                }
				else
					amiVideo_convertScreenBitplanesToRGBPixels(screen); /* Convert the bitplanes to RGB pixels */

			}
		}
	}
	else
	{
		if(format == SDL_ILBM_FORMAT_CHUNKY)
		{
			/* Convert the colors of the the bitplane palette to the format of the chunky palette */
			amiVideo_convertBitplaneColorsToChunkyFormat(&screen->palette);

			/* Set the palette of the target SDL surface */
			if(!SDL_ILBM_setPalette(img_out, &screen->palette))
				return FALSE;

			if(pixelChunk != NULL)
			{
				/* Populate the surface with pixels in chunky format */

				if(ILBM_imageIsPBM(image))
					amiVideo_correctScreenPixels(screen);
				else
					amiVideo_convertScreenBitplanesToCorrectedChunkyPixels(screen); /* Convert the bitplanes to corrected chunky pixels */

			}
		}
		else
		{
			/* Populate the surface with pixels in RGB format */
			if(pixelChunk != NULL)
			{

				if(ILBM_imageIsPBM(image))
				{
                    if(screen->bitplaneDepth == 24 || screen->bitplaneDepth == 32)
                    {
                        memcpy(screen->uncorrectedRGBFormat.pixels, pixelChunk->chunkData, pixelChunk->chunkSize);
                        amiVideo_reorderRGBPixels(screen);
                        amiVideo_correctScreenPixels(screen);
                    }
                    else
                    {
					    amiVideo_convertBitplaneColorsToChunkyFormat(&screen->palette);
					    amiVideo_convertScreenChunkyPixelsToCorrectedRGBPixels(screen);
				    }
                }
				else
					amiVideo_convertScreenBitplanesToCorrectedRGBPixels(screen); /* Convert the bitplanes to corrected RGB pixels */

			}
		}
	}

	return TRUE;
}

ilbm_image_out *SDL_ILBM_generateSurfaceFromScreen(const ILBM_Image *image, amiVideo_Screen *screen,
	const SDL_ILBM_Format format, const unsigned int lowresPixelScaleFactor)
{
	int depth, bytePerPixel;
	int width, height;
	int allocateUncorrectedMemory;
	int pitch;
	unsigned char *surface = NULL;
	ilbm_image_out *img = (ilbm_image_out*)malloc(sizeof(ilbm_image_out));

	if(format == SDL_ILBM_FORMAT_CHUNKY)
	{
		depth = 8;
		bytePerPixel = 1;
	}
	else
	{
		depth = 32;
		bytePerPixel = 4;
	}

	if(lowresPixelScaleFactor == 1)
	{
		width = screen->width;
		height = screen->height;
	}
	else
	{
		amiVideo_setLowresPixelScaleFactor(screen, lowresPixelScaleFactor);

		width = screen->correctedFormat.width;
		height = screen->correctedFormat.height;
	}

	/* Allocate memory */
	surface = (unsigned char *)malloc(width * height * bytePerPixel);
	memset(surface, 0, width * height * bytePerPixel);
	pitch = width * bytePerPixel;
	img->pixels = surface;
	img->width = width;
	img->height = height;
	img->depth = depth;
	img->colorsCount = 0;
	img->palette = NULL;

	/* Set the output format pointers */

	allocateUncorrectedMemory = !ILBM_imageIsPBM(image);

	if(lowresPixelScaleFactor == 1)
	{
		if(format == SDL_ILBM_FORMAT_CHUNKY)
			amiVideo_setScreenUncorrectedChunkyPixelsPointer(screen, surface, pitch); /* Sets the uncorrected chunky pixels pointer of the conversion struct to that of the SDL pixel surface */
		else
			amiVideo_setScreenUncorrectedRGBPixelsPointer(screen, (amiVideo_ULong *)surface, pitch, allocateUncorrectedMemory, 0, 8, 16, 24); /* Set the uncorrected RGB pixels pointer of the conversion struct to that of the SDL pixel surface */
	}
	else
	{
		if(format == SDL_ILBM_FORMAT_CHUNKY)
			amiVideo_setScreenCorrectedPixelsPointer(screen, surface, pitch, 1, allocateUncorrectedMemory, 0, 0, 0, 0); /* Set the corrected chunky pixels pointer of the conversion struct to the SDL pixel surface */
		else
			amiVideo_setScreenCorrectedPixelsPointer(screen, surface, pitch, 4, allocateUncorrectedMemory, 0, 8, 16, 24); /* Set the corrected RGB pixels pointer of the conversion struct to the SDL pixel surface */
	}

	/* Convert pixels */
	if(SDL_ILBM_convertScreenPixelsToSurfacePixels(image, img, screen, format, lowresPixelScaleFactor))
		return img;
	else
	{
		return NULL;
	}
}
