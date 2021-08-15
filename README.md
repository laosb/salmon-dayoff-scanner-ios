# Salmon Dayoff Scanner - iOS

## Notice

This is the QR code scanner app used on all gates of Hangzhou Dianzi University in 2020, before the transition to face recognition.

Private information has been replaced with `[REDACTED]`, which in many cases breaks the code from running, so if you decided to use, please search for `[REDACTED]` and replace with correct values accordingly.

This code is now released in [MIT](https://laosb.mit-license.org).

Note that the file `CodeScannerView.swift` is a modified copy from [twostraws/CodeScanner](https://github.com/twostraws/CodeScanner/), thus the [author's license](https://github.com/twostraws/CodeScanner/#license) (which is also MIT) applies.

---

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
