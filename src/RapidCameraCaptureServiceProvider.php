<?php

namespace PTeal79\RapidCameraCapture;

use Illuminate\Support\ServiceProvider;
use PTeal79\RapidCameraCapture\Commands\CopyAssetsCommand;

class RapidCameraCaptureServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->singleton(RapidCameraCapture::class, function () {
            return new RapidCameraCapture();
        });
    }

    public function boot(): void
    {
        if ($this->app->runningInConsole()) {
            $this->commands([
                CopyAssetsCommand::class,
            ]);
        }
    }
}
