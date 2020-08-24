#  Salmon Dayoff Scanner - iOS

This version of scanner is for specialized deployment.

## Configuration

All configuration of this app is done via QR codes.

The QR code should contains a string of JSON.

Note that actual JSON does not allow comments.

```js
{
  "token": "xxx", // The Lemon token for that matter.
  "name": "Test Gate", // Gate name, for display in app only.
  "direction": 1, // 1 for out, -1 for in.
  "stats": { // Optional, for resetting counts on the bottom of screen.
    "success": 0,
    "fail": 0,
    "error": 0
  }
}
```

For safety, when a QR code containing such a JSON string was shown to scanner, it would ask for iOS authorization. So proper authorization should be in place on that device.

