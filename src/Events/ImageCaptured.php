<?php

namespace PTeal79\RapidCameraCapture\Events;

use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class ImageCaptured
{
    use Dispatchable, SerializesModels;

    public function __construct(
        public string $filename,
        public string $path
    ) {}
}
