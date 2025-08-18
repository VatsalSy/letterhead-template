#!/bin/bash

# LaTeX Compilation Script
# Compiles LaTeX files and cleans temporary files while preserving synctex files
# for PDF-TeX synchronization in editors like VS Code and Cursor

set -e  # Exit on any error

# Color codes for output
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Global variables
COMPILE_COUNT=0
SUCCESS_COUNT=0
FAILED_FILES=()

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print script header
print_header() {
    echo "========================================"
    print_status "$BLUE" "    LaTeX Compilation Script"
    print_status "$BLUE" "    Preserves synctex for PDF sync"
    echo "========================================"
    echo
}

# Function to compile a tex file
compile_tex() {
    local texfile="$1"
    local basename="${texfile%.tex}"
    
    print_status "$BLUE" "📄 Compiling $texfile..."
    ((COMPILE_COUNT++))
    
    # Check if tex file exists
    if [ ! -f "$texfile" ]; then
        print_status "$RED" "❌ Error: $texfile not found"
        FAILED_FILES+=("$texfile")
        return 1
    fi
    
    # First pdflatex run with synctex
    print_status "$YELLOW" "   → Running pdflatex (1/3)..."
    if ! pdflatex -synctex=1 -interaction=nonstopmode "$texfile" > /dev/null 2>&1; then
        print_status "$RED" "❌ Error: First pdflatex run failed for $texfile"
        FAILED_FILES+=("$texfile")
        return 1
    fi
    
    # Run bibtex if .bib files exist
    if ls ./*.bib >/dev/null 2>&1; then
        print_status "$YELLOW" "   → Running bibtex..."
        if ! bibtex "$basename" > /dev/null 2>&1; then
            print_status "$YELLOW" "⚠️  Warning: bibtex failed for $basename (may be expected if no citations)"
        fi
    fi
    
    # Second pdflatex run
    print_status "$YELLOW" "   → Running pdflatex (2/3)..."
    if ! pdflatex -synctex=1 -interaction=nonstopmode "$texfile" > /dev/null 2>&1; then
        print_status "$RED" "❌ Error: Second pdflatex run failed for $texfile"
        FAILED_FILES+=("$texfile")
        return 1
    fi
    
    # Third pdflatex run for final references
    print_status "$YELLOW" "   → Running pdflatex (3/3)..."
    if ! pdflatex -synctex=1 -interaction=nonstopmode "$texfile" > /dev/null 2>&1; then
        print_status "$RED" "❌ Error: Final pdflatex run failed for $texfile"
        FAILED_FILES+=("$texfile")
        return 1
    fi
    
    # Check if PDF was generated
    if [ -f "${basename}.pdf" ]; then
        print_status "$GREEN" "✅ Successfully compiled $texfile → ${basename}.pdf"
        ((SUCCESS_COUNT++))
        return 0
    else
        print_status "$RED" "❌ Error: PDF not generated for $texfile"
        FAILED_FILES+=("$texfile")
        return 1
    fi
}

# Function to clean temporary files (preserving synctex and PDF)
clean_temp_files() {
    local basename="$1"
    
    print_status "$YELLOW" "🧹 Cleaning temporary files for $basename..."
    
    # Array of extensions to remove
    local temp_extensions=(
        "aux" "log" "out" "toc" "lof" "lot" "bbl" "blg" 
        "nav" "snm" "vrb" "dvi" "fdb_latexmk" "fls" 
        "ps" "eps" "eepic" "figlist" "makefile" "idx" 
        "ind" "ilg" "glo" "gls" "glg" "acn" "acr" "alg"
    )
    
    local removed_count=0
    for ext in "${temp_extensions[@]}"; do
        if [ -f "${basename}.${ext}" ]; then
            rm -f "${basename}.${ext}"
            ((removed_count++))
        fi
    done
    
    if [ $removed_count -gt 0 ]; then
        print_status "$GREEN" "   ✓ Removed $removed_count temporary file(s)"
    else
        print_status "$YELLOW" "   → No temporary files to clean"
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [FILE...]"
    echo
    echo "OPTIONS:"
    echo "  -h, --help     Show this help message"
    echo "  -c, --clean    Clean temporary files only (no compilation)"
    echo "  -v, --verbose  Show detailed compilation output"
    echo
    echo "EXAMPLES:"
    echo "  $0                    # Compile all .tex files in directory"
    echo "  $0 file.tex          # Compile specific file"
    echo "  $0 file1.tex file2.tex  # Compile multiple files"
    echo "  $0 --clean           # Clean temporary files only"
}

# Function to get all tex files in directory
get_tex_files() {
    find . -maxdepth 1 -name "*.tex" -type f | sort
}

# Function to clean all temporary files in directory
clean_all_temp() {
    print_status "$YELLOW" "🧹 Cleaning all temporary files in directory..."
    
    local cleaned_files=0
    for texfile in $(get_tex_files); do
        local basename="${texfile%.tex}"
        basename="${basename#./}"  # Remove ./ prefix
        clean_temp_files "$basename"
        ((cleaned_files++))
    done
    
    if [ $cleaned_files -eq 0 ]; then
        print_status "$YELLOW" "No .tex files found to clean"
    else
        print_status "$GREEN" "✅ Cleaned temporary files for $cleaned_files file(s)"
    fi
}

# Function to print final summary
print_summary() {
    echo
    echo "========================================"
    print_status "$BLUE" "           COMPILATION SUMMARY"
    echo "========================================"
    
    if [ $COMPILE_COUNT -eq 0 ]; then
        print_status "$YELLOW" "No files were compiled"
        return
    fi
    
    print_status "$GREEN" "✅ Successfully compiled: $SUCCESS_COUNT/$COMPILE_COUNT files"
    
    if [ ${#FAILED_FILES[@]} -gt 0 ]; then
        print_status "$RED" "❌ Failed files:"
        for file in "${FAILED_FILES[@]}"; do
            print_status "$RED" "   - $file"
        done
    fi
    
    echo
    print_status "$BLUE" "📁 Preserved files:"
    print_status "$BLUE" "   • PDF files (compiled output)"
    print_status "$BLUE" "   • .synctex.gz files (for editor sync)"
    print_status "$BLUE" "   • .tex and .bib files (source)"
    
    if [ $SUCCESS_COUNT -gt 0 ]; then
        echo
        print_status "$GREEN" "🔗 PDF-TeX synchronization enabled for:"
        print_status "$GREEN" "   VS Code, Cursor, and other compatible editors"
    fi
}

# Main function
main() {
    local files_to_compile=()
    local clean_only=false
    local verbose=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -c|--clean)
                clean_only=true
                shift
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            *.tex)
                files_to_compile+=("$1")
                shift
                ;;
            *)
                print_status "$RED" "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    print_header
    
    # If clean only mode
    if [ "$clean_only" = true ]; then
        clean_all_temp
        exit 0
    fi
    
    # If no files specified, compile all .tex files in directory
    if [ ${#files_to_compile[@]} -eq 0 ]; then
        mapfile -t files_to_compile < <(get_tex_files)
        
        if [ ${#files_to_compile[@]} -eq 0 ]; then
            print_status "$RED" "❌ No .tex files found in current directory"
            exit 1
        fi
        
        print_status "$BLUE" "📂 Found ${#files_to_compile[@]} .tex file(s) to compile"
    fi
    
    # Compile each file
    for texfile in "${files_to_compile[@]}"; do
        # Remove ./ prefix if present
        texfile="${texfile#./}"
        
        if compile_tex "$texfile"; then
            clean_temp_files "${texfile%.tex}"
        fi
        echo
    done
    
    print_summary
    
    # Exit with error code if any compilation failed
    if [ ${#FAILED_FILES[@]} -gt 0 ]; then
        exit 1
    fi
    
    exit 0
}

# Run main function with all arguments
main "$@"