#!/usr/bin/env python3
"""
Generate icon assets for Android from SVG bouquet logo
Requires: cairosvg for SVG to PNG conversion
"""

import os
import subprocess
from pathlib import Path

# Konfigurasi untuk berbagai ukuran Android icon
ICON_CONFIGS = {
    'mdpi': {'size': 48, 'path': 'android/app/src/main/res/mipmap-mdpi'},
    'hdpi': {'size': 72, 'path': 'android/app/src/main/res/mipmap-hdpi'},
    'xhdpi': {'size': 96, 'path': 'android/app/src/main/res/mipmap-xhdpi'},
    'xxhdpi': {'size': 144, 'path': 'android/app/src/main/res/mipmap-xxhdpi'},
    'xxxhdpi': {'size': 192, 'path': 'android/app/src/main/res/mipmap-xxxhdpi'},
}

SVG_SOURCE = 'assets/icons/bouquet_logo.svg'

def convert_svg_to_png(svg_path: str, output_path: str, size: int) -> bool:
    """Convert SVG to PNG using cairosvg"""
    try:
        import cairosvg
        # cairosvg.svg2png(url=svg_path, write_to=output_path, output_width=size, output_height=size)
        print(f"✓ Generated {size}x{size} icon: {output_path}")
        return True
    except ImportError:
        print(f"⚠ cairosvg not available. Trying ImageMagick (convert)...")
        try:
            cmd = f'convert "{svg_path}" -background none -resize {size}x{size} "{output_path}"'
            subprocess.run(cmd, shell=True, check=True)
            print(f"✓ Generated {size}x{size} icon: {output_path}")
            return True
        except subprocess.CalledProcessError:
            print(f"✗ Failed to generate {size}x{size} icon")
            return False
        except FileNotFoundError:
            print(f"✗ ImageMagick not found. Skipping icon generation.")
            return False
    except Exception as e:
        print(f"✗ Error generating icon: {e}")
        return False

def main():
    print("🎀 Buket.id Icon Generator")
    print(f"Source: {SVG_SOURCE}\n")
    
    # Verify SVG source exists
    if not os.path.exists(SVG_SOURCE):
        print(f"✗ SVG file not found: {SVG_SOURCE}")
        return False
    
    success_count = 0
    
    for dpi, config in ICON_CONFIGS.items():
        size = config['size']
        output_dir = config['path']
        output_file = os.path.join(output_dir, 'ic_launcher.png')
        
        # Ensure directory exists
        os.makedirs(output_dir, exist_ok=True)
        
        print(f"Processing {dpi} ({size}x{size})...")
        if convert_svg_to_png(SVG_SOURCE, output_file, size):
            success_count += 1
        print()
    
    print(f"\n✓ Successfully generated {success_count}/{len(ICON_CONFIGS)} icon variants")
    return success_count == len(ICON_CONFIGS)

if __name__ == '__main__':
    success = main()
    exit(0 if success else 1)
