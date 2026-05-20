# RISC-V Word Scrambler / Descrambler

A RISC-V assembly program that scrambles and descrambles a text message at the word level, implemented as part of the EECE321 Computer Organization course at the American University of Beirut.

## What it does

Given a sentence of 9 to 15 words and a numeric key, the program:
1. Prints the original message
2. Scrambles the word order using the key as a seed for a random number generator
3. Prints the scrambled message
4. Recovers and prints the original message using only the scrambled text and the same key

## How it works

**Scrambler:** The key seeds RARS's built-in RNG (syscall 40 — RandSeed). A Fisher-Yates shuffle then rearranges a word-index array `order[]` using RandIntRange (syscall 42), producing a deterministic scrambling that is fully controlled by the key.

**Descrambler:** The RNG is re-seeded with the same key and the Fisher-Yates shuffle is re-run from scratch, reconstructing the exact same permutation. The inverse of that permutation is then computed and used to recover the original word order — no swap history or extra data is needed beyond the key.

## Requirements

- [RARS 1.6](https://github.com/TheThirdOne/rars) (RISC-V Assembler and Runtime Simulator)
- Java 8 or higher (to run RARS)

## Running the program

1. Open RARS
2. Load `scrambler.asm` via **File → Open**
3. Click **Assemble** then **Run**
4. Output appears in the **Run I/O** tab

## Changing the input

At the top of the `.data` section in `scrambler.asm`:

```asm
message:    .string "the quick brown fox jumps over the lazy dog today"
key:        .word   12345
```

- Replace `message` with any sentence of **9 to 15 space-separated words**
- Replace `key` with any integer — different keys produce different scramblings

## Example output

```
Original:    the quick brown fox jumps over the lazy dog today
Scrambled:   today over jumps brown quick the fox the lazy dog
Descrambled: the quick brown fox jumps over the lazy dog today
```

## File structure

```
scrambler.asm   # main source file (scrambler + descrambler in one file)
README.md       # this file
```
