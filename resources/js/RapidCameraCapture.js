/**
 * RapidCameraCapture Plugin for NativePHP Mobile
 *
 * @example
 * import { RapidCameraCapture, Events } from '@pteal79/rapid-camera-capture';
 * import { On, Off } from '#nativephp';
 *
 * // Open the persistent camera interface
 * await RapidCameraCapture.open();
 *
 * // Listen for each captured image
 * const handler = (payload) => {
 *     console.log('Captured:', payload.filename, payload.path);
 * };
 * On(Events.ImageCaptured, handler);
 *
 * // Clean up when done
 * Off(Events.ImageCaptured, handler);
 */

const baseUrl = '/_native/api/call';

async function bridgeCall(method, params = {}) {
    const response = await fetch(baseUrl, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]')?.content || '',
        },
        body: JSON.stringify({ method, params }),
    });

    const result = await response.json();

    if (result.status === 'error') {
        throw new Error(result.message || 'Native call failed');
    }

    const nativeResponse = result.data;
    if (nativeResponse && nativeResponse.data !== undefined) {
        return nativeResponse.data;
    }

    return nativeResponse;
}

async function open() {
    return bridgeCall('RapidCameraCapture.OpenCamera');
}

export const RapidCameraCapture = {
    open,
};

export const Events = {
    ImageCaptured: 'PTeal79\\RapidCameraCapture\\Events\\ImageCaptured',
};

export default RapidCameraCapture;
