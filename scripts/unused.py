import os
import re
from pathlib import Path

def find_dart_files(directory):
    """Знаходить всі .dart файли в директорії"""
    dart_files = []
    for root, dirs, files in os.walk(directory):
        # Ігноруємо папки build, .dart_tool, etc.
        dirs[:] = [d for d in dirs if d not in ['.dart_tool', 'build', 'target', '.git']]
        
        for file in files:
            if file.endswith('.dart'):
                full_path = os.path.join(root, file)
                dart_files.append(full_path)
    return dart_files

def extract_imports(file_path):
    """Витягує всі імпорти з Dart файлу"""
    imports = set()
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            # Шукаємо import та export statements
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
        print(f"Помилка читання {file_path}: {e}")
    return imports

def normalize_path(file_path, project_root):
    """Нормалізує шлях для порівняння"""
    rel_path = os.path.relpath(file_path, project_root)
    # Перетворюємо в Unix стиль для однакового порівняння
    return rel_path.replace('\\', '/')

def find_unused_dart_files(project_path):
    """Головна функція пошуку невикористовуваних файлів"""
    project_path = os.path.abspath(project_path)
    print(f"Аналіз проекту: {project_path}\n")
    
    # Знаходимо всі Dart файли
    all_dart_files = find_dart_files(project_path)
    print(f"Знайдено Dart файлів: {len(all_dart_files)}")
    
    # Збираємо всі імпорти
    all_imports = set()
    files_with_imports = {}
    
    for dart_file in all_dart_files:
        imports = extract_imports(dart_file)
        files_with_imports[dart_file] = imports
        all_imports.update(imports)
    
    # Знаходимо файли, які використовуються
    used_files = set()
    
    for dart_file in all_dart_files:
        file_name = os.path.basename(dart_file)
        rel_path = normalize_path(dart_file, project_path)
        
        # Перевіряємо чи є посилання на цей файл в імпортах
        for imp in all_imports:
            if (imp.endswith(file_name) or 
                imp.endswith(rel_path) or
                rel_path in imp or
                file_name.replace('.dart', '') in imp):
                used_files.add(dart_file)
                break
    
    # Додаємо main файл (зазвичай використовується)
    for dart_file in all_dart_files:
        if os.path.basename(dart_file) == 'main.dart':
            used_files.add(dart_file)
    
    # Знаходимо невикористовувані файли
    unused_files = set(all_dart_files) - used_files
    
    # Виводимо результати
    print("\n" + "="*60)
    print("НЕВИКОРИСТОВУВАНІ DART ФАЙЛИ:")
    print("="*60)
    
    if unused_files:
        for file in sorted(unused_files):
            rel_path = normalize_path(file, project_path)
            size = os.path.getsize(file)
            print(f"  📄 {rel_path} ({size} bytes)")
        print(f"\nВсього невикористовуваних файлів: {len(unused_files)}")
    else:
        print("  ✅ Невикористовуваних файлів не знайдено!")
    
    # Статистика
    print("\n" + "="*60)
    print("СТАТИСТИКА:")
    print("="*60)
    print(f"Всього Dart файлів: {len(all_dart_files)}")
    print(f"Використовуваних: {len(used_files)}")
    print(f"Невикористовуваних: {len(unused_files)}")
    
    return unused_files

def main():
    import sys
    
    # Визначаємо шлях до проекту
    if len(sys.argv) > 1:
        project_path = sys.argv[1]
    else:
        project_path = os.getcwd()
    
    if not os.path.exists(project_path):
        print(f"Помилка: Шлях '{project_path}' не існує!")
        return
    
    unused = find_unused_dart_files(project_path)
    
    # Записуємо результати у файл
    if unused:
        output_file = "unused_dart_files.txt"
        with open(output_file, 'w', encoding='utf-8') as f:
            for file in sorted(unused):
                f.write(f"{file}\n")
        print(f"\n📝 Список збережено у файл: {output_file}")

if __name__ == "__main__":
    main()