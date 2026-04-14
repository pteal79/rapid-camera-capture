# RapidCameraCapture Plugin for NativePHP Mobile

A NativePHP plugin that opens a persistent camera interface on iOS. The user can tap **Take Photo** repeatedly to capture multiple images — the camera stays open between shots. Each captured image is saved to the `mobile_public` disk with a UUID filename and an `ImageCaptured` event is dispatched to PHP after every capture.

**Platform:** iOS only.

## Installation

```bash
composer require pteal79/rapid-camera-capture

# Publish the plugins provider (first time only)
php artisan vendor:publish --tag=nativephp-plugins-provider

# Register the plugin
php artisan native:plugin:register pteal79/rapid-camera-capture

# Verify
php artisan native:plugin:list
```

## Requirements

### iOS Permissions

The following is added to your app's `Info.plist` automatically via the plugin manifest:

| Key | Description |
|-----|-------------|
| `NSCameraUsageDescription` | Required for camera access |

## Usage

### Open the Camera

```php
use PTeal79\RapidCameraCapture\Facades\RapidCameraCapture;

RapidCameraCapture::open();
```

The camera interface is presented full-screen. The user can tap **Take Photo** as many times as they like. Each photo is saved immediately. The camera closes when the user taps **Close**.

### Handle Captured Images (Livewire)

```php
use Native\Mobile\Attributes\OnNative;
use PTeal79\RapidCameraCapture\Events\ImageCaptured;

#[OnNative(ImageCaptured::class)]
public function onImageCaptured(string $filename, string $path): void
{
    // $filename — UUID-based, e.g. "550e8400-e29b-41d4-a716-446655440000.jpg"
    // $path     — absolute path on the device filesystem

    // Serve the image via the mobile_public disk:
    $url = Storage::disk('mobile_public')->url($filename);
    $this->photos[] = $url;
}
```

## Events

### `ImageCaptured`

Fired after every successful photo capture, before the camera is ready for the next shot.

| Property   | Type   | Description                            |
|------------|--------|----------------------------------------|
| `filename` | string | UUID filename, e.g. `{uuid}.jpg`       |
| `path`     | string | Absolute path to the file on device    |

## JavaScript Usage

```javascript
import { RapidCameraCapture, Events } from '@pteal79/rapid-camera-capture';
import { On, Off } from '#nativephp';

// Open the camera
await RapidCameraCapture.open();

// React to each captured image
const handler = ({ filename, path }) => {
    console.log('New photo:', filename);
};

On(Events.ImageCaptured, handler);

// Clean up
Off(Events.ImageCaptured, handler);
```

## How It Works

The plugin uses `AVCaptureSession` with `AVCapturePhotoOutput` and `AVCaptureVideoPreviewLayer` for a live, persistent camera preview. Unlike `UIImagePickerController`, the session stays active so the user can capture an unlimited number of photos in one session. Each JPEG is written to the app's `mobile_public` storage directory with a UUID filename, then `LaravelBridge.shared.send` dispatches the `ImageCaptured` event back to PHP.

## License

MIT
