"""Generate meditation ambient sound files using the Python stdlib.

Produces looping-friendly procedural audio: rain, ocean waves, nature (forest
birds), flute, temple bells, wind chimes and crickets.

Key properties:
  * All sounds are NORMALIZED to a consistent, clearly audible peak (~80%).
  * All sounds are made LOOP-SEAMLESS with an equal-power crossfade so looping
    never produces clicks or pops.
  * Ambients are long (30-45s) so the loop point is less noticeable.
  * Output is MP3 (96 kbps mono, via the `lameenc` package) written directly
    to assets/sounds/, which keeps the APK small and plays on Android, web
    and iOS. The 16-bit WAV originals are written to tool/sounds_wav_backup/
    so they stay out of the app bundle (pubspec bundles assets/ wholesale).

Usage:
    python tool/generate_meditation_sounds.py
"""
import math
import os
import random
import struct
import wave

import lameenc

SR = 22050  # sample rate (Hz)
MP3_BITRATE = 96  # kbps
ASSETS_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'sounds')
WAV_BACKUP_DIR = os.path.join(os.path.dirname(__file__), 'sounds_wav_backup')


def _to_pcm16(samples):
    """Convert float samples in [-1, 1] to 16-bit PCM bytes."""
    data = bytearray()
    for s in samples:
        v = max(-1.0, min(1.0, s))
        data += struct.pack('<h', int(v * 32767))
    return bytes(data)


def write_sound(name, samples, sr=SR):
    """Write a sound as MP3 into assets/ plus a WAV original in the backup dir."""
    stem = name[:-4] if name.lower().endswith('.wav') else name
    pcm = _to_pcm16(samples)

    # WAV original -> backup folder (not bundled into the app)
    wav_path = os.path.normpath(os.path.join(WAV_BACKUP_DIR, stem + '.wav'))
    os.makedirs(WAV_BACKUP_DIR, exist_ok=True)
    with wave.open(wav_path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(pcm)

    # MP3 -> assets/sounds (bundled)
    enc = lameenc.Encoder()
    enc.set_bit_rate(MP3_BITRATE)
    enc.set_in_sample_rate(sr)
    enc.set_channels(1)
    enc.set_quality(2)
    out = bytearray()
    chunk = sr * 2
    for i in range(0, len(pcm), chunk):
        out += enc.encode(pcm[i:i + chunk])
    out += enc.flush()
    mp3_path = os.path.normpath(os.path.join(ASSETS_DIR, stem + '.mp3'))
    with open(mp3_path, 'wb') as f:
        f.write(out)

    print('wrote %s: %.1fs, MP3 %.1f KB (+ WAV backup)'
          % (stem, len(samples) / sr, len(out) / 1024))


def normalize(samples, target_peak=0.8):
    """Scale samples so the peak reaches target_peak (clearly audible, no clip)."""
    peak = max(abs(s) for s in samples) or 1.0
    gain = target_peak / peak
    return [s * gain for s in samples]


def make_loopable(samples, xf=1.0):
    """Blend the tail into the head so the file loops without a click.

    Standard technique: the first `xf` seconds become a crossfade between the
    original head and the original tail, then the tail is trimmed off.
    """
    n = int(SR * xf)
    if n <= 0 or n >= len(samples):
        return samples
    out = list(samples)
    for i in range(n):
        a = i / n  # 0 -> 1
        out[i] = out[i] * a + out[len(out) - n + i] * (1.0 - a)
    return out[:len(out) - n]


def lowpass_filter(samples, alpha):
    """One-pole low-pass filter (alpha in 0..1, smaller = darker)."""
    out = [0.0] * len(samples)
    y = 0.0
    for i, x in enumerate(samples):
        y += alpha * (x - y)
        out[i] = y
    return out


def mix(a, b, gain_b=1.0):
    n = min(len(a), len(b))
    out = a[:n]
    for i in range(n):
        out[i] = out[i] + b[i] * gain_b
    return out


# ---------------------------------------------------------------- rain ----
def make_rain(duration=45.0):
    n = int(SR * duration)
    rnd = random.Random(7)
    raw = [rnd.uniform(-1, 1) for _ in range(n)]
    bed = lowpass_filter(raw, 0.06)
    # Slow intensity swell so it breathes a little
    out = [0.0] * n
    for i in range(n):
        t = i / SR
        swell = 0.75 + 0.25 * math.sin(2 * math.pi * 0.13 * t)
        out[i] = bed[i] * swell
    # Add a few random droplet "taps" on top for realism
    for _ in range(int(duration * 6)):
        idx = rnd.randrange(0, n - 1000)
        dur = rnd.randint(120, 300)
        for j in range(dur):
            tt = j / SR
            env = math.sin(math.pi * tt / (dur / SR))
            out[idx + j] += rnd.uniform(-1, 1) * env * 0.25
    return normalize(out, 0.75)


# ---------------------------------------------------------------- ocean ----
def make_ocean(duration=45.0):
    n = int(SR * duration)
    rnd = random.Random(11)
    raw = [rnd.uniform(-1, 1) for _ in range(n)]
    hiss = lowpass_filter(raw, 0.05)
    out = [0.0] * n
    for i in range(n):
        t = i / SR
        swell = 0.5 + 0.5 * math.sin(2 * math.pi * 0.07 * t)
        ripple = 0.35 + 0.25 * math.sin(2 * math.pi * 0.23 * t + 1.2)
        env = max(0.0, min(1.0, swell * ripple))
        out[i] = hiss[i] * env
    rumble = [0.25 * math.sin(2 * math.pi * 0.06 * (i / SR)) for i in range(n)]
    out = mix(out, rumble, 0.5)
    return normalize(out, 0.75)


# ---------------------------------------------------------- ambient ----
def make_ambient(duration=45.0):
    """Soft, dreamy ambient pad (for the bubble game background).

    Slowly evolving sine chords + deep filtered noise so it is clearly audible
    (the old ambient.wav was nearly silent at ~12%% peak).
    """
    n = int(SR * duration)
    rnd = random.Random(29)
    # warm noise bed
    noise = lowpass_filter([rnd.uniform(-1, 1) for _ in range(n)], 0.02)
    # two detuned low sines slowly beating against each other
    out = [0.0] * n
    for i in range(n):
        t = i / SR
        swell = 0.6 + 0.4 * math.sin(2 * math.pi * 0.045 * t)
        chord = (0.5 * math.sin(2 * math.pi * 130.81 * t)
                 + 0.35 * math.sin(2 * math.pi * 196.0 * t)
                 + 0.2 * math.sin(2 * math.pi * 261.63 * t))
        out[i] = (chord * swell + noise[i] * 0.35) * 0.6
    return normalize(out, 0.8)


# ---------------------------------------------------------- nature (NEW) ----
def make_nature(duration=45.0):
    """Forest ambience: soft breeze bed + occasional bird calls."""
    rnd = random.Random(13)
    n = int(SR * duration)

    # Soft breeze: deeply low-passed noise with gentle swell
    breeze_raw = [rnd.uniform(-1, 1) for _ in range(n)]
    breeze = lowpass_filter(breeze_raw, 0.015)
    out = [0.0] * n
    for i in range(n):
        t = i / SR
        swell = 0.6 + 0.4 * math.sin(2 * math.pi * 0.05 * t + 0.8)
        out[i] = breeze[i] * swell * 0.5

    # Leaves rustle: slightly brighter noise, occasional gusts
    leaf_raw = [rnd.uniform(-1, 1) for _ in range(n)]
    leaf = lowpass_filter(leaf_raw, 0.03)
    for i in range(n):
        t = i / SR
        gust = max(0.0, math.sin(2 * math.pi * 0.09 * t + 2.0))
        out[i] += leaf[i] * gust * gust * 0.35

    # Bird calls: short melodic chirps at random moments
    def chirp(freq, dur):
        seg = int(SR * dur)
        return [math.sin(2 * math.pi * freq * (j / SR)) *
                math.sin(math.pi * j / seg) * 0.5 for j in range(seg)]

    t = 0.0
    while t < duration - 2.5:
        base = rnd.choice([2400.0, 2800.0, 3200.0, 2100.0, 3500.0])
        # a call = 2-4 short chirps sliding slightly in pitch
        n_chirps = rnd.randint(2, 4)
        gap = rnd.uniform(0.12, 0.25)
        start = int(t * SR)
        for c in range(n_chirps):
            freq = base * (1.0 + rnd.uniform(-0.15, 0.15))
            cseg = chirp(freq, rnd.uniform(0.09, 0.16))
            cs = start + int(c * (0.09 + gap) * SR)
            for j, v in enumerate(cseg):
                idx = cs + j
                if 0 <= idx < n:
                    out[idx] += v
        t += rnd.uniform(1.6, 4.2)

    return normalize(out, 0.8)


# ---------------------------------------------------------------- flute ----
def make_flute(duration=36.0, note_len=2.2):
    """Softer, richer pentatonic flute melody with echo tail."""
    rnd = random.Random(23)
    # A minor pentatonic across two octaves: A4 C5 D5 E5 G5 A5 C6 D6
    notes = [440.0, 523.25, 587.33, 659.25, 783.99, 880.0, 1046.5, 1174.66]
    n = int(SR * duration)
    out = [0.0] * n
    pos = 0.0
    note_idx = 0
    while pos < duration:
        freq = notes[note_idx % len(notes)]
        note_idx += 1
        seg = min(note_len, duration - pos)
        seg_n = int(SR * seg)
        for j in range(seg_n):
            t = j / SR
            vib = 1.0 + 0.006 * math.sin(2 * math.pi * 5.2 * t)
            attack = min(1.0, t / 0.18)
            release = min(1.0, (seg - t) / 0.45)
            env = attack * release
            s = (math.sin(2 * math.pi * freq * vib * t)
                 + 0.4 * math.sin(2 * math.pi * 2 * freq * vib * t)
                 + 0.15 * math.sin(2 * math.pi * 3 * freq * vib * t))
            out[int(pos * SR) + j] += s * env * 0.4
        pos += note_len * 0.85  # gentle overlap between phrases
    # Simple echo: add a delayed, decaying copy for a room-like tail
    echo_delay = int(SR * 0.35)
    echo = [0.0] * n
    for i in range(echo_delay, n):
        echo[i] = out[i - echo_delay] * 0.35
    # breath noise for realism
    breath = [rnd.uniform(-1, 1) * 0.02 for _ in range(n)]
    breath = lowpass_filter(breath, 0.2)
    out = mix(mix(out, echo, 1.0), breath, 1.0)
    return normalize(out, 0.8)


# ------------------------------------------------------- temple bells ----
def make_temple_bells(duration=32.0):
    """Deep temple bell strikes with long inharmonic decay, no clipping."""
    rnd = random.Random(31)
    n = int(SR * duration)
    out = [0.0] * n
    partials = [
        (1.00, 1.00, 4.5),
        (2.00, 0.55, 3.2),
        (2.94, 0.30, 2.6),
        (4.02, 0.16, 1.8),
    ]
    f0 = 236.0
    t = 0.0
    while t < duration - 5.0:
        strike_len = rnd.uniform(3.5, 5.5)
        start = int(t * SR)
        for i in range(int(strike_len * SR)):
            tt = i / SR
            if start + i >= n:
                break
            val = 0.0
            for mult, amp, tau in partials:
                f = f0 * mult
                detune = 1.0 + rnd.uniform(-0.004, 0.004)
                val += amp * math.sin(2 * math.pi * f * detune * tt) \
                    * math.exp(-tt / tau)
            out[start + i] += val * 0.28
        t += rnd.uniform(3.0, 5.5)
    # shimmer
    shimmer = [rnd.uniform(-1, 1) * 0.006 for _ in range(n)]
    out = mix(out, shimmer, 1.0)
    return normalize(out, 0.8)


# ------------------------------------------------------- wind chimes ----
def make_wind_chimes(duration=30.0):
    """Random pentatonic chime plucks with sparkling decay."""
    rnd = random.Random(47)
    notes = [1567.98, 1760.0, 2093.0, 2349.32, 2637.02, 3135.96]
    n = int(SR * duration)
    out = [0.0] * n
    t = 0.0
    while t < duration - 1.5:
        freq = notes[rnd.randrange(len(notes))] * rnd.uniform(0.98, 1.02)
        dur = rnd.uniform(0.9, 1.8)
        start = int(t * SR)
        for i in range(int(dur * SR)):
            tt = i / SR
            if start + i >= n:
                break
            val = (math.sin(2 * math.pi * freq * tt)
                   + 0.4 * math.sin(2 * math.pi * 3 * freq * tt)) \
                * math.exp(-tt / 0.55)
            out[start + i] += val * 0.22
        t += rnd.uniform(0.4, 1.1)
    return normalize(out, 0.8)


# ------------------------------------------------------------ crickets ----
def make_cricket(duration=45.0):
    """Cricket night: periodic high-frequency chirp bursts."""
    rnd = random.Random(59)
    n = int(SR * duration)
    out = [0.0] * n
    t = 0.0
    while t < duration - 2.0:
        chirp_freq = rnd.uniform(4100.0, 4600.0)
        pulses = rnd.randint(3, 5)
        start = int(t * SR)
        for p in range(pulses):
            p_start = start + int(p * SR * 0.06)
            for i in range(int(SR * 0.045)):
                idx = p_start + i
                if idx >= n:
                    break
                tt = i / SR
                env = math.sin(math.pi * tt / 0.045)
                out[idx] += math.sin(2 * math.pi * chirp_freq * tt) * env * 0.16
        t += rnd.uniform(1.4, 2.4)
    return normalize(out, 0.8)


def main():
    os.makedirs(ASSETS_DIR, exist_ok=True)
    # All ambient/looping sounds get the seamless-loop crossfade.
    # ambient (used as the bubble game background) is regenerated too,
    # since the old one was nearly silent.
    write_sound('ambient.wav', make_loopable(make_ambient()))
    write_sound('rain.wav', make_loopable(make_rain()))
    write_sound('ocean.wav', make_loopable(make_ocean()))
    write_sound('nature.wav', make_loopable(make_nature()))
    write_sound('flute.wav', make_loopable(make_flute()))
    write_sound('temple_bells.wav', make_loopable(make_temple_bells()))
    write_sound('wind_chimes.wav', make_loopable(make_wind_chimes()))
    write_sound('cricket.wav', make_loopable(make_cricket()))
    print('done.')


if __name__ == '__main__':
    main()
