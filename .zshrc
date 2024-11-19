# Function: Create directory tree excluding node_modules and copy as JSON
dirc() {
    # Initialize default values
    local declarations_only=false
    local contents=false
    local output_format="yaml"
    local depth=""
    local file_list=""
    local exclude_dir='node_modules'

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d)
                declarations_only=true
                shift
                ;;
            -c)
                contents=true
                declarations_only=false
                shift
                ;;
            -json)
                output_format="json"
                shift
                ;;
            -L*)
                depth="${1#-L}"
                shift
                ;;
            *,*)
                file_list="$1"
                shift
                ;;
            *)
                if [[ -n "$1" ]]; then
                    file_list="$1"
                fi
                shift
                ;;
        esac
    done

    # Call Python and pass variables as environment variables
    export DECLARATIONS_ONLY="$declarations_only"
    export CONTENTS="$contents"
    export FILE_LIST="$file_list"
    export OUTPUT_FORMAT="$output_format"
    export SEARCH_DEPTH="$depth"

    output=$(python3 - <<'EOF'
import os
import sys
import re
import json
import yaml
import glob

def find_files_recursively(patterns):
    found_files = set()
    if patterns:
        patterns = [p.strip() for p in patterns.split(',')]
        for pattern in patterns:
            for ext in ['swift', 'js', 'ts', 'jsx', 'tsx', 'cpp', 'h', 'py', 'm', 'mm']:
                matches = glob.glob(f'**/{pattern}.{ext}', recursive=True)
                matches.extend(glob.glob(f'**/{pattern}', recursive=True))
                found_files.update(matches)
    else:
        # If no patterns specified, get all files with supported extensions
        for ext in ['swift', 'js', 'ts', 'jsx', 'tsx', 'cpp', 'h', 'py', 'm', 'mm']:
            matches = glob.glob(f'**/*.{ext}', recursive=True)
            found_files.update(matches)
    return sorted(list(found_files))

def extract_declarations(content):
    declarations = []
    lines = content.split('\n')
    in_multiline_comment = False
    
    declaration_pattern = r'^(?:public\s+|private\s+|protected\s+|internal\s+|fileprivate\s+|open\s+)?(?:final\s+)?(?:class|struct|enum|protocol|func|def|function|interface|module|namespace)\s+(\w+)'
    
    for line in lines:
        stripped_line = line.strip()
        
        if stripped_line.startswith('/*'):
            in_multiline_comment = True
            continue
        if stripped_line.endswith('*/'):
            in_multiline_comment = False
            continue
        if in_multiline_comment or stripped_line.startswith('//'):
            continue
            
        match = re.search(declaration_pattern, stripped_line)
        if match:
            declarations.append(stripped_line)
            
    return declarations

def build_file_tree(files):
    tree = {}
    for file in files:
        parts = os.path.normpath(file).split(os.sep)
        current = tree
        for part in parts[:-1]:
            if part not in current:
                current[part] = {'files': [], 'directories': {}}
            current = current[part]['directories']
        current.setdefault('files', []).append(parts[-1])
    return tree

class CleanDumper(yaml.SafeDumper):
    def represent_str(self, data):
        return self.represent_scalar('tag:yaml.org,2002:str', data, style='|')

def main():
    file_list = os.environ.get('FILE_LIST', '')
    declarations_only = os.environ.get('DECLARATIONS_ONLY') == 'true'
    contents = os.environ.get('CONTENTS') == 'true'
    output_format = os.environ.get('OUTPUT_FORMAT', 'yaml')
    
    files_to_process = find_files_recursively(file_list)
    
    if not files_to_process:
        print("No matching files found")
        return

    result = {}

    if contents:
        # For content mode, always use JSON output
        for filepath in files_to_process:
            try:
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                    result[filepath] = content
            except Exception as e:
                result[filepath] = f"Error reading file: {e}"
        print(json.dumps(result, indent=2))
    elif declarations_only:
        for filepath in files_to_process:
            try:
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                    declarations = extract_declarations(content)
                    if declarations:
                        result[filepath] = declarations
            except Exception as e:
                result[filepath] = f"Error reading file: {e}"
        # Use yaml for declarations
        print(yaml.dump(result, default_flow_style=False, sort_keys=False, allow_unicode=True))
    else:
        # Default behavior: show file hierarchy
        result = build_file_tree(files_to_process)
        print(yaml.dump(result, default_flow_style=False, sort_keys=False, allow_unicode=True))

if __name__ == '__main__':
    main()
EOF
)

    # Copy the output to the clipboard using pbcopy
    echo -n "$output" | pbcopy >/dev/null 2>&1
    echo "Output copied to clipboard."
}
