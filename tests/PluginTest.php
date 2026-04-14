<?php

beforeEach(function () {
    $this->pluginPath = dirname(__DIR__);
    $this->manifestPath = $this->pluginPath . '/nativephp.json';
});

describe('Plugin Manifest', function () {
    it('has a valid nativephp.json file', function () {
        expect(file_exists($this->manifestPath))->toBeTrue();

        $manifest = json_decode(file_get_contents($this->manifestPath), true);
        expect(json_last_error())->toBe(JSON_ERROR_NONE);
    });

    it('has required fields', function () {
        $manifest = json_decode(file_get_contents($this->manifestPath), true);

        expect($manifest)->toHaveKeys(['namespace', 'bridge_functions', 'events']);
    });

    it('declares the OpenCamera bridge function for iOS only', function () {
        $manifest = json_decode(file_get_contents($this->manifestPath), true);

        $functions = $manifest['bridge_functions'];
        expect($functions)->toBeArray()->toHaveCount(1);

        $openCamera = $functions[0];
        expect($openCamera['name'])->toBe('RapidCameraCapture.OpenCamera');
        expect($openCamera)->toHaveKey('ios');
        expect($openCamera)->not->toHaveKey('android');
    });

    it('declares the ImageCaptured event', function () {
        $manifest = json_decode(file_get_contents($this->manifestPath), true);

        expect($manifest['events'])->toContain('PTeal79\\RapidCameraCapture\\Events\\ImageCaptured');
    });

    it('has NSCameraUsageDescription in iOS info_plist', function () {
        $manifest = json_decode(file_get_contents($this->manifestPath), true);

        expect($manifest['ios']['info_plist'])->toHaveKey('NSCameraUsageDescription');
        expect($manifest['ios']['info_plist']['NSCameraUsageDescription'])->not->toBeEmpty();
    });
});

describe('iOS Native Code', function () {
    it('has bridge functions Swift file', function () {
        $file = $this->pluginPath . '/resources/ios/Sources/RapidCameraCaptureFunctions.swift';
        expect(file_exists($file))->toBeTrue();
    });

    it('has view controller Swift file', function () {
        $file = $this->pluginPath . '/resources/ios/Sources/RapidCameraCaptureViewController.swift';
        expect(file_exists($file))->toBeTrue();
    });

    it('bridge functions file contains OpenCamera class', function () {
        $file = $this->pluginPath . '/resources/ios/Sources/RapidCameraCaptureFunctions.swift';
        expect(file_get_contents($file))->toContain('class OpenCamera: BridgeFunction');
    });

    it('view controller uses AVCaptureSession for persistent camera', function () {
        $file = $this->pluginPath . '/resources/ios/Sources/RapidCameraCaptureViewController.swift';
        $contents = file_get_contents($file);

        expect($contents)->toContain('AVCaptureSession');
        expect($contents)->toContain('AVCapturePhotoOutput');
        expect($contents)->toContain('AVCaptureVideoPreviewLayer');
    });

    it('view controller dispatches ImageCaptured event via LaravelBridge', function () {
        $file = $this->pluginPath . '/resources/ios/Sources/RapidCameraCaptureViewController.swift';
        $contents = file_get_contents($file);

        expect($contents)->toContain('LaravelBridge.shared.send');
        expect($contents)->toContain('PTeal79\\\\RapidCameraCapture\\\\Events\\\\ImageCaptured');
    });
});

describe('PHP Classes', function () {
    it('has service provider', function () {
        $file = $this->pluginPath . '/src/RapidCameraCaptureServiceProvider.php';
        expect(file_exists($file))->toBeTrue();
    });

    it('has facade', function () {
        $file = $this->pluginPath . '/src/Facades/RapidCameraCapture.php';
        expect(file_exists($file))->toBeTrue();
    });

    it('has main implementation class', function () {
        $file = $this->pluginPath . '/src/RapidCameraCapture.php';
        expect(file_exists($file))->toBeTrue();
    });

    it('has ImageCaptured event class', function () {
        $file = $this->pluginPath . '/src/Events/ImageCaptured.php';
        expect(file_exists($file))->toBeTrue();
    });

    it('ImageCaptured event has filename and path properties', function () {
        $file = $this->pluginPath . '/src/Events/ImageCaptured.php';
        $contents = file_get_contents($file);

        expect($contents)->toContain('public string $filename');
        expect($contents)->toContain('public string $path');
    });
});

describe('Composer Configuration', function () {
    it('has valid composer.json', function () {
        $composerPath = $this->pluginPath . '/composer.json';
        expect(file_exists($composerPath))->toBeTrue();

        $composer = json_decode(file_get_contents($composerPath), true);
        expect(json_last_error())->toBe(JSON_ERROR_NONE);
        expect($composer['type'])->toBe('nativephp-plugin');
        expect($composer['name'])->toBe('pteal79/rapid-camera-capture');
    });
});
