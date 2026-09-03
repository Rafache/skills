import os
import re
import sys

def clean_movie_filename(filename):
    # Try to find the year (19xx or 20xx)
    year_match = re.search(r'\b(19\d{2}|20\d{2})\b', filename)

    if year_match:
        year = year_match.group(1)
        title_part = filename[:year_match.start()]
    else:
        year = ""
        tags_match = re.search(r'\b(MULTi|FRENCH|TRUEFRENCH|1080p|720p|2160p|BDRip|WEB|CUSTOM)\b', filename, re.IGNORECASE)
        if tags_match:
            title_part = filename[:tags_match.start()]
        else:
            title_part = os.path.splitext(filename)[0]

    title = title_part.replace(".", " ").replace("_", " ").strip()
    title = re.sub(r'[\(\)\[\]-]', ' ', title)
    title = re.sub(r'\s+', ' ', title).strip()

    ext = os.path.splitext(filename)[1]

    new_name = title
    if year:
        new_name += f" ({year})"
    new_name += ext

    return new_name

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python rename.py <filename>")
        sys.exit(1)

    # Just print the clean name
    print(clean_movie_filename(sys.argv[1]))
