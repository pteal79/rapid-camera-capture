## pteal79/rapid-camera-capture

A NativePHP plugin that opens a persistent camera interface on iOS. The user can tap **Take Photo** repeatedly to capture multiple images without the camera closing between shots. Each captured image is saved to the `mobile_public` disk with a UUID filename. An `ImageCaptured` event is dispatched to PHP after every capture.

**Platform:** iOS only.

### Installation

```bash
# Install the package
composer require pteal79/rapid-camera-capture

# Publish the plugins provider (first time only)
php artisan vendor:publish --tag=nativephp-plugins-provider

# Register the plugin
php artisan native:plugin:register pteal79/rapid-camera-capture

# Verify registration
php artisan native:plugin:list
```

This adds `\PTeal79\RapidCameraCapture\RapidCameraCaptureServiceProvider::class` to your `plugins()` array in `NativePluginsServiceProvider`.

### iOS Permissions Required

Add to your app's `Info.plist` (handled automatically by the plugin manifest):

- `NSCameraUsageDescription` — required for camera access.

### PHP Usage (Livewire/Blade)

@verbatim
<code-snippet name="Opening the camera" lang="php">
use PTeal79\RapidCameraCapture\Facades\RapidCameraCapture;

// Open the camera interface — stays open until the user taps Close
RapidCameraCapture::open();
</code-snippet>
@endverbatim

### Listening for Captured Images

Each photo taken fires an `ImageCaptured` event. The file is already saved to `mobile_public` before the event fires.

@verbatim
<code-snippet name="Handling ImageCaptured in Livewire" lang="php">
use Native\Mobile\Attributes\OnNative;
use PTeal79\RapidCameraCapture\Events\ImageCaptured;

#[OnNative(ImageCaptured::class)]
public function onImageCaptured(string $filename, string $path): void
{
    // $filename — e.g. "550e8400-e29b-41d4-a716-446655440000.jpg"
    // $path     — absolute path on the device

    // Display in a Blade/Livewire view via the mobile_public disk:
    $url = Storage::disk('mobile_public')->url($filename);
    $this->photos[] = $url;
}
</code-snippet>
@endverbatim

### Event Payload

| Property   | Type   | Description                                  |
|------------|--------|----------------------------------------------|
| `filename` | string | UUID-based filename, e.g. `{uuid}.jpg`       |
| `path`     | string | Absolute file path on the device             |

### JavaScript Usage (Vue/React/Inertia)

@verbatim
<code-snippet name="Using RapidCameraCapture in JavaScript" lang="javascript">
import { RapidCameraCapture, Events } from '@pteal79/rapid-camera-capture';
import { On, Off } from '#nativephp';

// Open the camera
await RapidCameraCapture.open();

// Listen for each captured image
const handler = (payload) => {
    console.log('Captured:', payload.filename, payload.path);
};
On(Events.ImageCaptured, handler);

// Clean up
Off(Events.ImageCaptured, handler);
</code-snippet>
@endverbatim
