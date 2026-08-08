"""Convert the WAV sounds in assets/sounds/ to compressed MP3 files.

Uses the `lameenc` package (bundles the LAME encoder, no external tools).
MP3 is chosen because it plays on Android (ExoPlayer), web (HTML5 audio) and
iOS (AVPlayer) — OGG/Vorbis would not play on iOS.

After encoding, the original .wav files are moved to tool/sounds_wav_backup/
so they stay available for regeneration but are NOT bundled into the app
(pubspec bundles assets/sounds/ as a whole directory).

Usage:
    python tool/convert_sounds_to_mp3.py
"""

import math
import os
import shutil
import struct
import wave

import lameenc

SRC_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'sounds')
BACKUP_DIR = os.path.join(os.path.dirname(__file__), 'sounds_wav_backup')
BITRATE = 96  # kbps — plenty for ambient/meditation audio


def convert_wav_to_mp3(wav_path, mp3_path, bitrate=BITRATE):
    """Encode a 16-bit PCM WAV file to an MP3 file."""
    with wave.open(wav_path, 'rb') as w:
        channels = w.getnchannels()
        rate = w.getframerate()
        sw = w.getsampwidth()
        n = w.getnframes()
        raw = w.readframes(n)

    # Normalize to 16-bit mono PCM bytes (lameenc needs int16)
    if sw == 2 and channels == 1:
        pcm = raw
    elif sw == 2 and channels > 1:
        vals = struct.unpack('<%dh' % (n * channels), raw)
        mono = [sum(vals[i * channels:(i + 1) * channels]) // channels
                for i in range(n)]
        pcm = struct.pack('<%dh' % n, *mono)
    elif sw == 1:
        vals = [struct.unpack('<B', raw[i:i + 1])[0] - 128 for i in range(len(raw))]
        pcm = struct.pack('<%dh' % len(vals), *vals)
    else:
        raise ValueError('Unsupported WAV format: %d bit' % (sw * 8))

    enc = lameenc.Encoder()
    enc.set_bit_rate(bitrate)
    enc.set_in_sample_rate(rate)
    enc.set_channels(1)
    enc.set_quality(2)  # 2 = high quality / low speed

    # LAME wants int16 bytes; feed in chunks to bound memory.
    chunk = 22050 * 2  # 1 second of mono int16
    out = bytearray()
    for i in range(0, len(pcm), chunk):
        out += enc.encode(pcm[i:i + chunk])
    out += enc.flush()

    with open(mp3_path, 'wb') as f:
        f.write(out)
    return len(out)


def main():
    os.makedirs(BACKUP_DIR, exist_ok=True)
    total_saved = 0
    for name in sorted(os.listdir(SRC_DIR)):
        if not name.lower().endswith('.wav'):
            continue
        wav_path = os.path.join(SRC_DIR, name)
        mp3_path = os.path.join(SRC_DIR, name[:-4] + '.mp3')
        wav_size = os.path.getsize(wav_path)
        mp3_size = convert_wav_to_mp3(wav_path, mp3_path)
        ratio = (1 - mp3_size / wav_size) * 100
        total_saved += wav_size - mp3_size
        # Move the original WAV out of the bundled assets folder
        shutil.move(wav_path, os.path.join(BACKUP_DIR, name))
        print('%-22s %8.0f KB -> %8.0f KB  (-%4.0f%%)'
              % (name, wav_size / 1024, mp3_size / 1024, ratio))
    print('\nTotal space freed: %.1f MB' % (total_saved / 1024 / 1024))
    print('WAV originals moved to: %s' % BACKUP_DIR)


if __name__ == '__main__':
    main()
