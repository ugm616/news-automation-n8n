#!/usr/bin/env python3
"""
Generate Subtitles (SRT format)
Creates word-level timed subtitles for videos
"""

import sys
import json
import re
from datetime import timedelta

def parse_transcript_with_timing(transcript_json):
    """
    Parse transcript JSON with word-level timing
    Expected format: [{"word": "Hello", "start": 0.0, "end": 0.5}, ...]
    """
    try:
        data = json.loads(transcript_json)
        return data
    except json.JSONDecodeError as e:
        print(f"[ERROR] Invalid JSON: {e}", file=sys.stderr)
        sys.exit(1)

def format_time(seconds):
    """
    Convert seconds to SRT time format (HH:MM:SS,mmm)
    """
    td = timedelta(seconds=seconds)
    hours = int(td.total_seconds() // 3600)
    minutes = int((td.total_seconds() % 3600) // 60)
    seconds = td.total_seconds() % 60
    milliseconds = int((seconds % 1) * 1000)
    seconds = int(seconds)
    
    return f"{hours:02d}:{minutes:02d}:{seconds:02d},{milliseconds:03d}"

def generate_srt(words, words_per_subtitle=5):
    """
    Generate SRT subtitle file content
    """
    srt_content = []
    subtitle_index = 1
    
    i = 0
    while i < len(words):
        # Get chunk of words
        chunk = words[i:i+words_per_subtitle]
        
        if not chunk:
            break
        
        # Get timing
        start_time = chunk[0]['start']
        end_time = chunk[-1]['end']
        
        # Get text
        text = ' '.join([w['word'] for w in chunk])
        
        # Format SRT entry
        srt_entry = f"{subtitle_index}\n"
        srt_entry += f"{format_time(start_time)} --> {format_time(end_time)}\n"
        srt_entry += f"{text}\n"
        
        srt_content.append(srt_entry)
        subtitle_index += 1
        i += words_per_subtitle
    
    return '\n'.join(srt_content)

def generate_word_by_word_srt(words):
    """
    Generate SRT with word-by-word highlighting
    Better for TikTok-style subtitles
    """
    srt_content = []
    
    for idx, word_data in enumerate(words, 1):
        start_time = word_data['start']
        end_time = word_data['end']
        word = word_data['word']
        
        # Format SRT entry
        srt_entry = f"{idx}\n"
        srt_entry += f"{format_time(start_time)} --> {format_time(end_time)}\n"
        srt_entry += f"{word}\n"
        
        srt_content.append(srt_entry)
    
    return '\n'.join(srt_content)

def simple_timing_from_text(text, duration, words_per_subtitle=5):
    """
    Generate simple timed subtitles from plain text
    Distributes timing evenly across words
    """
    words = text.split()
    total_words = len(words)
    time_per_word = duration / total_words
    
    words_with_timing = []
    current_time = 0.0
    
    for word in words:
        word_data = {
            'word': word,
            'start': current_time,
            'end': current_time + time_per_word
        }
        words_with_timing.append(word_data)
        current_time += time_per_word
    
    return generate_srt(words_with_timing, words_per_subtitle)

def main():
    if len(sys.argv) < 2:
        print("[ERROR] Usage: python generate_subtitles.py <input_json>", file=sys.stderr)
        print("Input JSON format:", file=sys.stderr)
        print('  {"type": "timed", "words": [...]}', file=sys.stderr)
        print('  OR', file=sys.stderr)
        print('  {"type": "simple", "text": "...", "duration": 60}', file=sys.stderr)
        sys.exit(1)
    
    input_json = sys.argv[1]
    
    try:
        data = json.loads(input_json)
    except json.JSONDecodeError as e:
        print(f"[ERROR] Invalid JSON: {e}", file=sys.stderr)
        sys.exit(1)
    
    subtitle_type = data.get('type', 'simple')
    
    if subtitle_type == 'timed':
        # Word-by-word with timing
        words = data['words']
        style = data.get('style', 'grouped')  # 'grouped' or 'word-by-word'
        
        if style == 'word-by-word':
            srt_content = generate_word_by_word_srt(words)
        else:
            words_per_line = data.get('words_per_subtitle', 5)
            srt_content = generate_srt(words, words_per_line)
    
    elif subtitle_type == 'simple':
        # Simple timing from text
        text = data['text']
        duration = data['duration']
        words_per_line = data.get('words_per_subtitle', 5)
        
        srt_content = simple_timing_from_text(text, duration, words_per_line)
    
    else:
        print(f"[ERROR] Unknown type: {subtitle_type}", file=sys.stderr)
        sys.exit(1)
    
    # Output SRT content
    print(srt_content)
    
    # Also output metadata as JSON to stderr
    metadata = {
        "success": True,
        "subtitle_count": len(srt_content.split('\n\n')) if srt_content else 0
    }
    print(json.dumps(metadata), file=sys.stderr)

if __name__ == '__main__':
    main()
