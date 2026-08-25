#!/usr/bin/env python3
"""Regenerates lib/utils/gita_verse_data.dart with the COMPLETE Bhagavad Gita.

Fetches all 701 verses (18 chapters) from the free, no-key API at
https://vedicscriptures.github.io/slok/{chapter}/{verse} and emits a Dart file
with the same class shape as the existing dataset:
  [shloka, transliteration, translationEnglish, translationHindi, commentary, commentaryHindi]

Usage:  python tool/generate_gita_data.py
"""
import json
import re
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

try:
    import urllib.request as urlreq
    import urllib.error as urlerr
except ImportError:  # pragma: no cover
    raise

BASE = "https://vedicscriptures.github.io/slok"
# Verse counts per chapter (matches AppConstants.gitaChapters)
CHAPTER_VERSES = [47, 72, 43, 42, 29, 47, 30, 28, 34, 42, 55, 20, 35, 27, 20, 24, 28, 78]

TIMEOUT = 30
RETRIES = 4
CONCURRENCY = 8


def fetch_verse(chapter: int, verse: int):
    url = f"{BASE}/{chapter}/{verse}"
    last_err = None
    for attempt in range(RETRIES):
        try:
            req = urlreq.Request(url, headers={"User-Agent": "divine-path-gita-generator/1.0"})
            with urlreq.urlopen(req, timeout=TIMEOUT) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except Exception as e:  # noqa: BLE001
            last_err = e
            time.sleep(1.0 * (attempt + 1))
    raise RuntimeError(f"chapter {chapter} verse {verse} failed: {last_err}")


def clean_shloka(text: str) -> str:
    """Remove trailing '||२-१||' / '||2-1||' verse markers from the shloka."""
    if not text:
        return ""
    text = re.sub(r"\s*\|\|[^|]*\|\|\s*$", "", text.strip())
    return text


def clean_transliteration(text: str) -> str:
    if not text:
        return ""
    return re.sub(r"\s*\|\|[^|]*\|\|\s*$", "", text.strip())


def clean_english(text: str) -> str:
    """Strip leading '2.1 ' verse markers from English translations/comments."""
    if not text:
        return ""
    return re.sub(r"^\s*\d+\.\d+\s+", "", text.strip())


def clean_hindi(text: str) -> str:
    """Strip leading '।।2.1।।' markers from Hindi translations/comments."""
    if not text:
        return ""
    return re.sub(r"^\s*।।\s*[\d०-९\.]+\s*।।\s*", "", text.strip())


def clean_commentary(text: str) -> str:
    """Clean commentary text for display.

    The source API uses '?' as a separator inside Sivananda-style word glosses
    (e.g. 'यत्र wherever? योगेश्वरः the Lord of Yoga?') and inside prose where
    punctuation belongs. Replace it with a comma, collapse whitespace, and tidy
    repeated commas so the bottom commentary section renders cleanly.
    """
    if not text:
        return ""
    text = re.sub(r"\?\s*", ", ", text)
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r",\s*,+", ",", text)
    text = re.sub(r"\s+([.,;:])", r"\1", text)
    text = re.sub(r",\s+", ", ", text)
    return text.strip()


def verse_fields(data: dict) -> list:
    slok = clean_shloka(data.get("slok", ""))
    translit = clean_transliteration(data.get("transliteration", ""))

    # English translation: prefer Sivananda, fall back to Purohit
    en = ""
    siva = data.get("siva") or {}
    if siva.get("et"):
        en = clean_english(siva["et"])
    if not en:
        purohit = data.get("purohit") or {}
        en = clean_english(purohit.get("et", ""))

    # Hindi translation: Tejomayananda
    tej = data.get("tej") or {}
    hi = clean_hindi(tej.get("ht", ""))

    # Commentaries
    en_comment = clean_commentary(clean_english(siva.get("ec", "")))
    chinmay = data.get("chinmay") or {}
    hi_comment = clean_commentary(clean_hindi(chinmay.get("hc", "")))

    return [slok, translit, en, hi, en_comment, hi_comment]


def dart_string(s: str) -> str:
    """Escape a string as a Dart double-quoted literal (JSON-compatible escapes)."""
    return json.dumps(s, ensure_ascii=False).replace("$", r"\$")


def main() -> int:
    print("Fetching all 701 verses...", file=sys.stderr)
    all_data = {}
    failures = []

    def worker(chapter, verse):
        try:
            raw = fetch_verse(chapter, verse)
            return (chapter, verse, verse_fields(raw))
        except Exception as e:  # noqa: BLE001
            return (chapter, verse, None)

    with ThreadPoolExecutor(max_workers=CONCURRENCY) as pool:
        futures = [
            pool.submit(worker, ch, v)
            for ch, count in enumerate(CHAPTER_VERSES, start=1)
            for v in range(1, count + 1)
        ]
        for fut in as_completed(futures):
            chapter, verse, fields = fut.result()
            if fields is None:
                failures.append((chapter, verse))
                continue
            all_data.setdefault(chapter, {})[verse] = fields

    if failures:
        print(f"WARNING: {len(failures)} verses failed:", file=sys.stderr)
        for ch, v in failures[:50]:
            print(f"  chapter {ch} verse {v}", file=sys.stderr)

    # Emit the Dart file
    out = []
    out.append("/// A single verse matched by [GitaVerseData.search].")
    out.append("class VerseSearchResult {")
    out.append("  final int chapterNumber;")
    out.append("  final int verseNumber;")
    out.append("")
    out.append("  /// The 6-element verse record: [shloka, transliteration, translationEnglish,")
    out.append("  /// translationHindi, commentary, commentaryHindi].")
    out.append("  final List<String> fields;")
    out.append("")
    out.append("  VerseSearchResult({")
    out.append("    required this.chapterNumber,")
    out.append("    required this.verseNumber,")
    out.append("    required this.fields,")
    out.append("  });")
    out.append("")
    out.append("  String get shloka => fields.isNotEmpty ? fields[0] : '';")
    out.append("  String get transliteration => fields.length > 1 ? fields[1] : '';")
    out.append("  String get translationEnglish => fields.length > 2 ? fields[2] : '';")
    out.append("  String get translationHindi => fields.length > 3 ? fields[3] : '';")
    out.append("}")
    out.append("")
    out.append("/// Complete Bhagavad Gita verse content — keyed by (chapter, verse).")
    out.append("///")
    out.append("/// All 701 verses across the 18 chapters are included. Each record is")
    out.append("/// [shloka, transliteration, translationEnglish, translationHindi,")
    out.append("/// commentary, commentaryHindi].")
    out.append("/// Generated by tool/generate_gita_data.py — do not hand-edit the _data map.")
    out.append("class GitaVerseData {")
    out.append("  /// Returns a map of verseNumber -> [shloka, transliteration, translationEnglish,")
    out.append("  /// translationHindi, commentary, commentaryHindi] for the given chapter,")
    out.append("  /// or null if the chapter has no local content yet.")
    out.append("  static Map<int, List<String>>? chapter(int chapterNumber) => _data[chapterNumber];")
    out.append("")
    out.append("  /// Finds a verse, returning null if it isn't in the local dataset.")
    out.append("  static List<String>? find(int chapterNumber, int verseNumber) {")
    out.append("    return chapter(chapterNumber)?[verseNumber];")
    out.append("  }")
    out.append("")
    out.append("  /// Case-insensitive keyword search across every verse in the local dataset.")
    out.append("  /// Matches the shloka, transliteration, English/Hindi translations and both")
    out.append("  /// commentaries. Returns an empty list for a blank query.")
    out.append("  static List<VerseSearchResult> search(String query) {")
    out.append("    final q = query.trim().toLowerCase();")
    out.append("    if (q.isEmpty) return const [];")
    out.append("")
    out.append("    final results = <VerseSearchResult>[];")
    out.append("    _data.forEach((chapterNumber, verses) {")
    out.append("      verses.forEach((verseNumber, fields) {")
    out.append("        final matched = fields.any((field) => field.toLowerCase().contains(q));")
    out.append("        if (matched) {")
    out.append("          results.add(VerseSearchResult(")
    out.append("            chapterNumber: chapterNumber,")
    out.append("            verseNumber: verseNumber,")
    out.append("            fields: fields,")
    out.append("          ));")
    out.append("        }")
    out.append("      });")
    out.append("    });")
    out.append("    return results;")
    out.append("  }")
    out.append("")
    out.append("  static const Map<int, Map<int, List<String>>> _data = {")
    for chapter in range(1, 19):
        verses = all_data.get(chapter, {})
        out.append(f"    // ─────────── Chapter {chapter} ───────────")
        out.append(f"    {chapter}: {{")
        for verse in range(1, CHAPTER_VERSES[chapter - 1] + 1):
            fields = verses.get(verse)
            if fields is None:
                # Shouldn't happen after fetch; emit empty record as a safety net.
                fields = ["", "", "", "", "", ""]
            out.append(f"      {verse}: [")
            for i, f in enumerate(fields):
                comma = "," if i < len(fields) - 1 else ""
                out.append(f"        {dart_string(f)}{comma}")
            out.append("      ],")
        out.append("    },")
    out.append("  };")
    out.append("}")

    path = "lib/utils/gita_verse_data.dart"
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")

    fetched = sum(len(v) for v in all_data.values())
    print(f"Done. {fetched}/701 verses written to {path}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
