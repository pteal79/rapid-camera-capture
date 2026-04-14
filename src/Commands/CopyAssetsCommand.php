<?php

namespace PTeal79\RapidCameraCapture\Commands;

use Native\Mobile\Plugins\Commands\NativePluginHookCommand;

class CopyAssetsCommand extends NativePluginHookCommand
{
    protected $signature = 'nativephp:rapid-camera-capture:copy-assets';

    protected $description = 'Copy assets for RapidCameraCapture plugin';

    public function handle(): int
    {
        if ($this->isIos()) {
            $this->copyIosAssets();
        }

        return self::SUCCESS;
    }

    protected function copyIosAssets(): void
    {
        $this->info('iOS assets copied for RapidCameraCapture');
    }
}
