import os
import re

def extract_queries(sql_path, image_folder):
    with open(sql_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    output = []
    query = []
    heading = ''
    question_number = ''

    for line in lines:
        line_strip = line.strip()

        # Detect query header line: must start with -- and include ")"
        if line_strip.startswith('--') and re.match(r'--\s*\d+\)', line_strip):
            if query:
                output.append(format_block(heading, query, question_number, image_folder))
                query = []

            heading_raw = line_strip[2:].strip()
            heading = heading_raw
            question_number_match = re.findall(r'\d+', heading_raw.split(')')[0])
            question_number = question_number_match[0].zfill(2) if question_number_match else '00'

        else:
            # Even lines like "-- comment" are part of the query unless it's a new header
            query.append(line)

    if query:
        output.append(format_block(heading, query, question_number, image_folder))

    return '\n\n'.join(output)

def format_block(heading, query_lines, qnum, image_folder):
    image_file = next((f for f in os.listdir(image_folder) if f.startswith(qnum)), None)
    img_tag = ''
    if image_file:
        alt_text = image_file.replace('.png', '')
        # Extract folder name only to make the path relative
        relative_folder = os.path.basename(image_folder)
        img_tag = f'<img src="{relative_folder}/{image_file}" alt="{alt_text}" height="300"/>'

    formatted_query = ''.join(['```sql\n'] + query_lines + ['```\n'])
    return f'## {heading}\n\n<details>\n  <summary>Show SQL Query</summary>\n\n{formatted_query}</details><br>\n\n{img_tag}'

# Usage
md_content = extract_queries(
    "C:/Users/aryan/My Projects/AryanJha/Data Science/Indian-Premiere-League-Analysis/SQL-Files/IPL-Demo.sql",
    "C:/Users/aryan/My Projects/AryanJha/Data Science/Indian-Premiere-League-Analysis/MarkdownTable/RemoveBG-Outputs"
)

try:
    readme_path = os.path.join(
        "C:/Users/aryan/My Projects/AryanJha/Data Science/Indian-Premiere-League-Analysis/MarkdownTable","ipl-readme.md"
    )
    with open(readme_path, 'w', encoding='utf-8') as f:
        f.write(md_content)
    print("File saved successfully.")
except Exception as e:
    print("Error saving file:", e)
