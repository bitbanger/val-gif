#!/usr/bin/env bash

# The lengths of times for each video segment
CONSOLE_SECS=18
GAME_SECS=3

# The factors by which to speed each segment up
CONSOLE_SPEEDUP=10
GAME_SPEEDUP=1

# The number of extra seconds to "linger" on each
# segment *after* the speedup.
CONSOLE_LINGER=2
GAME_LINGER=0

# These times are used to trim the final, sped-up videos,
# since ffmpeg seems to leave the entire video in there.
CONSOLE_TIME=$(((${CONSOLE_SECS} / ${CONSOLE_SPEEDUP}) + ${CONSOLE_LINGER}))
GAME_TIME=$(((${GAME_SECS} / ${GAME_SPEEDUP}) + ${GAME_LINGER}))

# Clean up
mv VAL-overcooked-edited.mp4 VAL-overcooked-edited.other
rm *.mp4 2>/dev/null
rm val.gif 2>/dev/null
mv VAL-overcooked-edited.other VAL-overcooked-edited.mp4

# Split the original video into the console and game
# halves, leaving the timelines alone for now
ffmpeg -i VAL-overcooked-edited.mp4 -filter:v "crop=605:508:0:0" console.mp4
ffmpeg -i VAL-overcooked-edited.mp4 -filter:v "crop=675:508:605:0" game.mp4

# Speed up each half
ffmpeg -t ${CONSOLE_SECS} -i console.mp4 -vf "setpts=PTS/${CONSOLE_SPEEDUP},fps=30" console_fast.mp4
ffmpeg -ss ${CONSOLE_SECS} -t $((${CONSOLE_SECS}+${GAME_SECS})) -i game.mp4 -vf "setpts=PTS/${GAME_SPEEDUP},fps=30" game_fast.mp4

# Trim the sped-up halves to their final times
ffmpeg -ss 0 -to ${CONSOLE_TIME} -i console_fast.mp4 -c copy console_trimmed.mp4
ffmpeg -ss 0 -to ${GAME_TIME} -i game_fast.mp4 -c copy game_trimmed.mp4

# Concatenate the two halves into one video
ffmpeg -i console_trimmed.mp4 -i game_trimmed.mp4 -filter_complex "[0:v]scale=674:508:force_original_aspect_ratio=decrease,pad=674:508:(ow-iw)/2:(oh-ih)/2[v0]; [v0][0:a] [1:v] [1:a] concat=n=2:v=1:a=1 [v] [a]" -map "[v]" -map "[a]" concat.mp4

# Convert the concatenated video into a GIF
ffmpeg -i concat.mp4 -vf "fps=10,scale=674:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0 val.gif

# Clean up
mv VAL-overcooked-edited.mp4 VAL-overcooked-edited.other
rm *.mp4 2>/dev/null
mv VAL-overcooked-edited.other VAL-overcooked-edited.mp4
