<?php

namespace PTeal79\RapidCameraCapture;

class RapidCameraCapture
{
    /**
     * Open the persistent camera capture interface.
     *
     * The camera stays open until the user dismisses it. Each captured photo
     * is saved to the mobile_public disk with a UUID filename and an
     * ImageCaptured event is dispatched for every photo taken.
     */
    public function open(): void
    {
        if (function_exists('nativephp_call')) {
            nativephp_call('RapidCameraCapture.OpenCamera', '{}');
        }
    }
}
