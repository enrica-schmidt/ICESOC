#!/usr/bin/env python3
"""Convert a hex byte file (one byte per line) into a C header file.

Each group of four bytes is packed into one uint32_t entry, with the
first byte occupying the LSBs (little-endian byte order within the word).
"""

import argparse
import sys
from pathlib import Path


def parse_hex_file(path: Path) -> list[int]:
    """Read a hex file and return a list of byte values (0-255)."""
    bytes_out: list[int] = []
    for lineno, raw in enumerate(path.read_text().splitlines(), start=1):
        line = raw.strip()
        if not line:
            continue
        try:
            value = int(line, 16)
        except ValueError:
            print(f"Error: invalid hex value {line!r} on line {lineno}", file=sys.stderr)
            sys.exit(1)
        if not (0 <= value <= 0xFF):
            print(f"Error: byte value {value:#x} out of range on line {lineno}", file=sys.stderr)
            sys.exit(1)
        bytes_out.append(value)
    return bytes_out


def pack_words(byte_values: list[int], pad: bool = True) -> list[int]:
    """Pack bytes into uint32_t words, first byte in LSBs.

    If the number of bytes is not a multiple of four and *pad* is True,
    the final word is zero-padded.  Otherwise an error is raised.
    """
    remainder = len(byte_values) % 4
    if remainder:
        if pad:
            byte_values = byte_values + [0x00] * (4 - remainder)
        else:
            print(
                f"Error: byte count ({len(byte_values)}) is not a multiple of 4. "
                "Use --pad to zero-pad the last word.",
                file=sys.stderr,
            )
            sys.exit(1)

    words: list[int] = []
    for i in range(0, len(byte_values), 4):
        b0, b1, b2, b3 = byte_values[i : i + 4]
        word = b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)
        words.append(word)
    return words


def array_name_from_stem(stem: str) -> str:
    """Derive a valid C identifier from a file stem."""
    ident = "".join(ch if ch.isalnum() or ch == "_" else "_" for ch in stem)
    if ident and ident[0].isdigit():
        ident = "_" + ident
    return ident or "data"


def generate_header(
    words: list[int],
    guard: str,
    source_filename: str,
    pad_words: int = 0,
) -> str:
    """Render the C header file as a string.

    *pad_words* zero-valued entries are appended after the data words.
    The SIZE macro reflects the total length including padding.
    """
    all_words = [0x00000000] * pad_words + words
    columns = 5  # uint32_t entries per line

    lines: list[str] = []
    lines.append(f"/* Auto-generated from {source_filename} — do not edit manually. */")
    lines.append("")
    lines.append(f"#ifndef {guard}")
    lines.append(f"#define {guard}")
    lines.append("")
    lines.append("#include <stdint.h>")
    lines.append("")
    lines.append(f"#define PROGRAM_LENGTH {len(all_words)}U")
    lines.append("")
    lines.append(f"volatile static const uint32_t program_data[PROGRAM_LENGTH] = {{")

    for chunk_start in range(0, len(all_words), columns):
        # Insert a blank separator line between padding and data regions.
        if pad_words and chunk_start == (pad_words // columns) * columns and chunk_start > 0 and chunk_start <= pad_words:
            lines.append("")
        chunk = all_words[chunk_start : chunk_start + columns]
        hex_values = ", ".join(f"0x{w:08X}U" for w in chunk)
        is_last_chunk = (chunk_start + columns) >= len(all_words)
        trailing = "" if is_last_chunk else ","
        lines.append(f"    {hex_values}{trailing}")

    lines.append("};")
    lines.append("")
    lines.append(f"#endif /* {guard} */")
    lines.append("")

    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Convert a hex byte file (one byte per line) into a C header "
            "containing a const uint32_t array.  Bytes are packed "
            "little-endian: the first byte occupies the LSBs of each word."
        )
    )
    parser.add_argument(
        "input",
        type=Path,
        metavar="INPUT",
        help="Input hex file (one hex byte per line).",
    )
    parser.add_argument(
        "-o", "--output",
        type=Path,
        metavar="OUTPUT",
        default=None,
        help=(
            "Output header file path.  Defaults to the input file stem "
            "with a .h extension in the current directory."
        ),
    )
    parser.add_argument(
        "-n", "--name",
        metavar="IDENTIFIER",
        default=None,
        help=(
            "C identifier to use for the array and macros.  "
            "Defaults to a sanitised version of the input file stem."
        ),
    )
    parser.add_argument(
        "--guard",
        metavar="GUARD",
        default=None,
        help=(
            "Header-guard macro name.  "
            "Defaults to the array name in upper-case followed by _H."
        ),
    )
    parser.add_argument(
        "--pad",
        action="store_true",
        default=False,
        help=(
            "Zero-pad the last word when the byte count is not a multiple "
            "of four (default: error out)."
        ),
    )
    parser.add_argument(
        "--pad-words",
        type=int,
        metavar="N",
        default=0,
        help=(
            "Number of zero-valued uint32_t words to append after the data "
            "entries (default: 0 (disabled))."
        ),
    )
    args = parser.parse_args()

    if args.pad_words < 0:
        print("Error: --pad-words must be a non-negative integer.", file=sys.stderr)
        sys.exit(1)

    if not args.input.is_file():
        print(f"Error: {args.input} is not a regular file.", file=sys.stderr)
        sys.exit(1)

    output_path: Path = args.output or Path(args.input.stem).with_suffix(".h")
    array_name: str = args.name or array_name_from_stem(args.input.stem)
    guard: str = args.guard or f"{array_name.upper()}_H"

    byte_values = parse_hex_file(args.input)
    words = pack_words(byte_values, pad=args.pad)
    header = generate_header(words, guard, args.input.name, pad_words=args.pad_words)

    output_path.write_text(header)
    total = len(words) + args.pad_words
    print(
        f"Written {len(words)} data + {args.pad_words} pad = {total} uint32_t entries "
        f"({len(byte_values)} bytes) to {output_path}"
    )


if __name__ == "__main__":
    main()
