import os
import re

files = [
    'lib/core/data/repositories/offline_first_orders_repository.dart',
    'lib/core/network/local_sync_client.dart',
    'lib/core/network/offline_queue.dart',
    'lib/features/menu/menu_management_screen.dart',
    'lib/features/orders/application/state/orders_notifier.dart',
    'lib/features/orders/data/datasources/orders_mock_datasource.dart',
    'lib/features/staff/staff_management_screen.dart'
]

for file_path in files:
    full_path = os.path.join('v:/All Projects/g8g ROS Main/Orderlli/tableosapk/tableos_admin', file_path)
    
    with open(full_path, 'r', encoding='utf-8') as f:
        content = f.read()

    changed = False

    # 1. Replace usages
    if 'UuidGenerator.generateRuntimeId' in content:
        # Replace prefixed usage
        content = re.sub(
            r"UuidGenerator\.generateRuntimeId\(\s*prefix:\s*'([^']+)'\s*\)", 
            r"'\1-${uuid.v4()}'", 
            content
        )
        # Replace non-prefixed usage
        content = re.sub(
            r"UuidGenerator\.generateRuntimeId\(\)", 
            r"uuid.v4()", 
            content
        )
        changed = True

    # 2. Fix imports and add top-level uuid
    # Remove the local uuid.dart import
    if re.search(r"import\s+'[^']*utils/uuid\.dart';\s*\n", content):
        content = re.sub(r"import\s+'[^']*utils/uuid\.dart';\s*\n", "", content)
        changed = True

    # If the file now uses uuid, ensure package is imported and uuid instance exists
    if 'uuid.v4()' in content:
        if "import 'package:uuid/uuid.dart';" not in content:
            # Insert after the last import statement
            imports_end = [m.end() for m in re.finditer(r"^import\s+.*?;$", content, re.MULTILINE)]
            if imports_end:
                last_import_idx = imports_end[-1]
                content = content[:last_import_idx] + "\nimport 'package:uuid/uuid.dart';\n\nfinal uuid = Uuid();\n" + content[last_import_idx:]
            else:
                content = "import 'package:uuid/uuid.dart';\n\nfinal uuid = Uuid();\n" + content
            changed = True
        else:
            # Package is imported, just ensure 'final uuid = Uuid();' exists globally
            if "final uuid = Uuid();" not in content and "const uuid = Uuid();" not in content:
                content = re.sub(
                    r"(import 'package:uuid/uuid\.dart';\s*\n)", 
                    r"\1\nfinal uuid = Uuid();\n", 
                    content
                )
                changed = True
            
            # If it has const uuid = Uuid(); replace it
            if "const uuid = Uuid();" in content:
                content = content.replace("const uuid = Uuid();", "final uuid = Uuid();")
                changed = True

    if changed:
        with open(full_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed {file_path}")
