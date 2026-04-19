import os
import re


def find_dart_files(directory):
    """Finds all .dart files in a directory"""
    dart_files = []
    for root, dirs, files in os.walk(directory):
        # Ignore the build, .dart_tool, etc. folders.
        dirs[:] = [
            d for d in dirs if d not in [".dart_tool", "build", "target", ".git"]
        ]

        for file in files:
            if file.endswith(".dart"):
                full_path = os.path.join(root, file)
                dart_files.append(full_path)
    return dart_files


def extract_imports(file_path):
    """Extracts all imports from a Dart file"""
    imports = set()
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
            # Looking for import and export statements
            patterns = [
                r"import\s+['\"]([^'\"]+)['\"]",
                r"export\s+['\"]([^'\"]+)['\"]",
                r"part\s+['\"]([^'\"]+)['\"]",
            ]
            for pattern in patterns:
                matches = re.findall(pattern, content)
                for match in matches:
                    imports.add(match)
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
    return imports


def normalize_path(file_path, project_root):
    """Normalizes the path for comparison"""
    rel_path = os.path.relpath(file_path, project_root)
    # Convert to Unix style for equal comparison
    return rel_path.replace("\\", "/")


def find_unused_dart_files(project_path):
    """Main function to find unused files"""
    project_path = os.path.abspath(project_path)
    print(f"Project Analysis: {project_path}\n")

    # Find all Dart files
    all_dart_files = find_dart_files(project_path)
    print(f"Dart files found: {len(all_dart_files)}")

    # Collect all imports
    all_imports = set()
    files_with_imports = {}

    for dart_file in all_dart_files:
        imports = extract_imports(dart_file)
        files_with_imports[dart_file] = imports
        all_imports.update(imports)

    # Find files that are in use
    used_files = set()

    for dart_file in all_dart_files:
        file_name = os.path.basename(dart_file)
        rel_path = normalize_path(dart_file, project_path)

        # Check if there is a reference to this file in the imports
        for imp in all_imports:
            if (
                imp.endswith(file_name)
                or imp.endswith(rel_path)
                or rel_path in imp
                or file_name.replace(".dart", "") in imp
            ):
                used_files.add(dart_file)
                break

    # Add the main file (usually used)
    for dart_file in all_dart_files:
        if os.path.basename(dart_file) == "main.dart":
            used_files.add(dart_file)

    # Find unused files
    unused_files = set(all_dart_files) - used_files

    # Print the results
    print("\n" + "=" * 60)
    print("UNUSED DART FILES:")
    print("=" * 60)

    if unused_files:
        for file in sorted(unused_files):
            rel_path = normalize_path(file, project_path)
            size = os.path.getsize(file)
            print(f"  📄 {rel_path} ({size} bytes)")
        print(f"\nTotal unused files: {len(unused_files)}")
    else:
        print(" ✅ No unused files found!")

    # Statistics
    print("\n" + "=" * 60)
    print("STATISTICS:")
    print("=" * 60)
    print(f"Total Dart files: {len(all_dart_files)}")
    print(f"Used: {len(used_files)}")
    print(f"Unused: {len(unused_files)}")

    return unused_files


def main():
    import sys

    # Determine the path to the project
    if len(sys.argv) > 1:
        project_path = sys.argv[1]
    else:
        project_path = os.getcwd()

    if not os.path.exists(project_path):
        print(f"Error: Path '{project_path}' does not exist!")
        return

    unused = find_unused_dart_files(project_path)

    # Write the results to a file
    if unused:
        output_file = "unused_dart_files.txt"
        with open(output_file, "w", encoding="utf-8") as f:
            for file in sorted(unused):
                f.write(f"{file}\n")
        print(f"\n📝 List saved to file: {output_file}")


if __name__ == "__main__":
    main()
