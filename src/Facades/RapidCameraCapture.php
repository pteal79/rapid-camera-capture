<?php

namespace PTeal79\RapidCameraCapture\Facades;

use Illuminate\Support\Facades\Facade;

/**
 * @method static void open()
 *
 * @see \PTeal79\RapidCameraCapture\RapidCameraCapture
 */
class RapidCameraCapture extends Facade
{
    protected static function getFacadeAccessor(): string
    {
        return \PTeal79\RapidCameraCapture\RapidCameraCapture::class;
    }
}
