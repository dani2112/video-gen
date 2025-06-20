#!/usr/bin/env python3
"""
Script to patch diffusers for offline mode by commenting out problematic lines
in hub_utils.py that try to fetch model info from Hugging Face Hub.
"""

import os
import sys
import site
from pathlib import Path


def find_diffusers_hub_utils():
    """Find the hub_utils.py file in the diffusers package."""
    # Get all site-packages directories
    site_packages = site.getsitepackages()
    if hasattr(site, 'getusersitepackages'):
        site_packages.append(site.getusersitepackages())
    
    for site_dir in site_packages:
        hub_utils_path = Path(site_dir) / "diffusers" / "utils" / "hub_utils.py"
        if hub_utils_path.exists():
            return hub_utils_path
    
    # Fallback: try to find it relative to diffusers module
    try:
        import diffusers
        diffusers_path = Path(diffusers.__file__).parent
        hub_utils_path = diffusers_path / "utils" / "hub_utils.py"
        if hub_utils_path.exists():
            return hub_utils_path
    except ImportError:
        pass
    
    return None


def patch_hub_utils(file_path):
    """Patch the hub_utils.py file to comment out problematic lines."""
    print(f"Patching {file_path}")
    
    # Read the original file
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Expected patterns to find and comment out
    expected_patterns = [
        "model_files_info = model_info(pretrained_model_name_or_path, revision=revision, token=token)",
        "for shard_file in original_shard_filenames:",
        "shard_file_present = any(shard_file in k.rfilename for k in model_files_info.siblings)",
        "if not shard_file_present:",
        "raise EnvironmentError(",
        "f\"{shards_path} does not appear to have a file named {shard_file} which is",
        "\"required according to the checkpoint index.\"",
        ")"
    ]
    
    # Split content into lines
    lines = content.split('\n')
    
    # Track what we've found and patched
    commented_lines = []
    found_patterns = []
    modified = False
    
    # Find and comment out the problematic section
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Look for the start of the problematic section
        if "model_files_info = model_info(pretrained_model_name_or_path, revision=revision, token=token)" in line:
            print(f"Found problematic section starting at line {i + 1}")
            section_start_line = i + 1
            
            # Comment out this line and the following block
            if not line.strip().startswith('#'):
                lines[i] = '    # ' + line.strip()  # Comment out the model_info line
                commented_lines.append((i + 1, line.strip()))
                found_patterns.append("model_files_info = model_info(...)")
                modified = True
                print(f"  → Commented out line {i + 1}: {line.strip()}")
            
            # Continue with the for loop and its contents
            i += 1
            while i < len(lines):
                current_line = lines[i]
                current_line_stripped = current_line.strip()
                
                # Check if we're still in the problematic block
                should_comment = False
                pattern_found = None
                
                if current_line_stripped.startswith('for shard_file in original_shard_filenames:'):
                    should_comment = True
                    pattern_found = "for shard_file in original_shard_filenames:"
                elif current_line_stripped.startswith('shard_file_present = any('):
                    should_comment = True
                    pattern_found = "shard_file_present = any(...)"
                elif current_line_stripped.startswith('if not shard_file_present:'):
                    should_comment = True
                    pattern_found = "if not shard_file_present:"
                elif current_line_stripped.startswith('raise EnvironmentError('):
                    should_comment = True
                    pattern_found = "raise EnvironmentError("
                elif current_line_stripped.startswith('f"{shards_path} does not appear'):
                    should_comment = True
                    pattern_found = "f\"{shards_path} does not appear..."
                elif current_line_stripped.startswith('"required according to the checkpoint'):
                    should_comment = True
                    pattern_found = "\"required according to the checkpoint...\""
                elif current_line_stripped == ')' and i > section_start_line:
                    should_comment = True
                    pattern_found = ") [closing EnvironmentError]"
                
                if should_comment:
                    # Comment out if not already commented
                    if not current_line_stripped.startswith('#') and current_line_stripped:
                        # Preserve indentation
                        indent = len(current_line) - len(current_line.lstrip())
                        lines[i] = current_line[:indent] + '# ' + current_line.lstrip()
                        commented_lines.append((i + 1, current_line_stripped))
                        found_patterns.append(pattern_found)
                        modified = True
                        print(f"  → Commented out line {i + 1}: {current_line_stripped}")
                    
                    i += 1
                    
                    # If we hit the closing parenthesis of the EnvironmentError, we're done
                    if current_line_stripped == ')':
                        break
                else:
                    # We've moved past the problematic block
                    break
            
            break
        
        i += 1
    
    # Report results
    print(f"\n📊 PATCH SUMMARY:")
    print(f"   • Total lines commented out: {len(commented_lines)}")
    print(f"   • Expected patterns to find: {len(expected_patterns)}")
    print(f"   • Found patterns: {len(set(found_patterns))}")
    
    if commented_lines:
        print(f"\n📝 COMMENTED OUT LINES:")
        for line_num, line_content in commented_lines:
            print(f"   Line {line_num}: {line_content}")
    
    # Check if we found all expected patterns
    expected_simplified = [
        "model_files_info = model_info(...)",
        "for shard_file in original_shard_filenames:",
        "shard_file_present = any(...)",
        "if not shard_file_present:",
        "raise EnvironmentError(",
        "f\"{shards_path} does not appear...",
        "\"required according to the checkpoint...\"",
        ") [closing EnvironmentError]"
    ]
    
    found_set = set(found_patterns)
    expected_set = set(expected_simplified)
    missing_patterns = expected_set - found_set
    
    if missing_patterns:
        print(f"\n⚠️  WARNING: Some expected patterns were not found:")
        for pattern in missing_patterns:
            print(f"   • {pattern}")
    else:
        print(f"\n✅ All expected patterns were found and processed!")
    
    if modified:
        # Write the modified content back
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write('\n'.join(lines))
        print(f"\n🎯 Successfully patched hub_utils.py for offline mode!")
        print(f"   Modified {len(commented_lines)} lines in total")
        return True
    else:
        print(f"\nℹ️  No modifications needed - file may already be patched or structure has changed.")
        return False


def main():
    """Main function to patch diffusers for offline mode."""
    print("Patching diffusers for offline mode...")
    
    # Find the hub_utils.py file
    hub_utils_path = find_diffusers_hub_utils()
    
    if not hub_utils_path:
        print("ERROR: Could not find diffusers/utils/hub_utils.py")
        print("Make sure diffusers is installed before running this script.")
        sys.exit(1)
    
    print(f"Found hub_utils.py at: {hub_utils_path}")
    
    # Create a backup
    backup_path = hub_utils_path.with_suffix('.py.backup')
    if not backup_path.exists():
        print(f"Creating backup at: {backup_path}")
        with open(hub_utils_path, 'r', encoding='utf-8') as src, \
             open(backup_path, 'w', encoding='utf-8') as dst:
            dst.write(src.read())
    
    # Apply the patch
    success = patch_hub_utils(hub_utils_path)
    
    if success:
        print("✅ Diffusers successfully patched for offline mode!")
    else:
        print("ℹ️  No changes were made to the file.")


if __name__ == "__main__":
    main() 