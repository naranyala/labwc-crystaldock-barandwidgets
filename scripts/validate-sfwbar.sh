#!/bin/bash
# -------------------------------------------------------------------
# SFWBar Config Validator
# Validates SFWBar configuration files for common issues:
# - Syntax errors (missing braces, quotes)
# - Invalid directives
# - Missing includes
# - Duplicate bar names
# - CSS token references
# -------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OCWS_DIR="${1:-$PROJECT_DIR/dotfiles/ocws}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

errors=0
warnings=0
info_count=0

pass() { echo -e "  ${GREEN}✓${NC} $1"; ((info_count++)); }
fail() { echo -e "  ${RED}✗${NC} $1"; ((errors++)); }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; ((warnings++)); }
info() { echo -e "  ${CYAN}ℹ${NC} $1"; }

echo "=== SFWBar Config Validator ==="
echo ""
echo "Checking configs in: $OCWS_DIR"
echo ""

# ============================================================
# 1. Find all SFWBar config files
# ============================================================
echo "--- Config Files ---"
config_files=()
for f in "$OCWS_DIR"/*.config "$OCWS_DIR"/*.mode; do
    [[ -f "$f" ]] || continue
    # Skip non-SFWBar configs (env.config, user.config, plugins.config)
    fname=$(basename "$f")
    [[ "$fname" == "env.config" ]] && continue
    [[ "$fname" == "user.config" ]] && continue
    [[ "$fname" == "plugins.config" ]] && continue
    config_files+=("$f")
done

if [[ ${#config_files[@]} -eq 0 ]]; then
    fail "No config files found in $OCWS_DIR"
    exit 1
fi

info "Found ${#config_files[@]} config files"
echo ""

# ============================================================
# 2. Validate each config file
# ============================================================
for config in "${config_files[@]}"; do
    cname=$(basename "$config")
    echo "--- Validating: $cname ---"
    
    # 2a. Check for #Api2 header
    if head -1 "$config" | grep -q "^#Api2"; then
        pass "Has #Api2 header"
    else
        warn "Missing #Api2 header"
    fi
    
    # 2b. Check brace matching
    open_braces=$(grep -c "{" "$config" 2>/dev/null || echo 0)
    close_braces=$(grep -c "}" "$config" 2>/dev/null || echo 0)
    if [[ $open_braces -eq $close_braces ]]; then
        pass "Braces balanced ($open_braces pairs)"
    else
        fail "Brace mismatch: $open_braces open, $close_braces close"
    fi
    
    # 2c. Check quote matching
    open_quotes=$(grep -o '"' "$config" 2>/dev/null | wc -l || echo 0)
    if (( open_quotes % 2 == 0 )); then
        pass "Quotes balanced ($open_quotes total)"
    else
        fail "Quote mismatch: $open_quotes quotes (odd number)"
    fi
    
    # 2d. Check for invalid directives
    if grep -qE "^(Set|bar|widget|include|switcher|scanner|function)" "$config" 2>/dev/null; then
        pass "Contains valid directives"
    else
        warn "No recognized directives found"
    fi
    
    # 2e. Check include() references
    while IFS= read -r line; do
        if [[ "$line" =~ include\(\"([^\"]+)\"\) ]]; then
            inc_file="${BASH_REMATCH[1]}"
            # Resolve path relative to config dir
            if [[ "$inc_file" == /* ]]; then
                inc_path="$inc_file"
            else
                inc_path="$OCWS_DIR/$inc_file"
            fi
            
            if [[ -f "$inc_path" ]]; then
                pass "Include found: $inc_file"
            else
                fail "Include not found: $inc_file"
            fi
        fi
    done < "$config"
    
    # 2f. Check bar definitions
    bar_count=$(grep -c "^bar " "$config" 2>/dev/null || echo 0)
    if [[ $bar_count -gt 0 ]]; then
        info "Defines $bar_count bar(s)"
        
        # Check for duplicate bar names
        declare -A bar_names
        while IFS= read -r line; do
            if [[ "$line" =~ bar[[:space:]]+\"([^\"]+)\" ]]; then
                bname="${BASH_REMATCH[1]}"
                if [[ -n "${bar_names[$bname]+x}" ]]; then
                    fail "Duplicate bar name: $bname"
                else
                    bar_names["$bname"]=1
                fi
            fi
        done < <(grep "^bar " "$config" 2>/dev/null)
        unset bar_names
    fi
    
    # 2g. Check for widget references
    widget_refs=$(grep -c 'widget "' "$config" 2>/dev/null || echo 0)
    if [[ $widget_refs -gt 0 ]]; then
        info "References $widget_refs widget(s)"
    fi
    
    # 2h. Check CSS section
    if grep -q "^#CSS" "$config" 2>/dev/null; then
        info "Has #CSS section"
        
        # Check for common CSS issues
        if grep -q "@define-color" "$config" 2>/dev/null; then
            info "Defines CSS color tokens"
        fi
    fi
    
    echo ""
done

# ============================================================
# 3. Check widget files referenced by configs
# ============================================================
echo "--- Widget References ---"
declare -A widget_files
for widget in "$OCWS_DIR"/*.widget; do
    [[ -f "$widget" ]] || continue
    wname=$(basename "$widget" .widget)
    widget_files["$wname"]=1
done

# Check all widget references in configs
for config in "${config_files[@]}"; do
    while IFS= read -r line; do
        if [[ "$line" =~ widget[[:space:]]+\"([^\"]+)\" ]]; then
            wname="${BASH_REMATCH[1]}"
            if [[ -n "${widget_files[$wname]+x}" ]]; then
                pass "Widget exists: $wname"
            else
                fail "Widget not found: $wname (referenced in $(basename "$config"))"
            fi
        fi
    done < "$config"
done
echo ""

# ============================================================
# 4. Check CSS token usage
# ============================================================
echo "--- CSS Token Usage ---"
token_usage=0
for config in "${config_files[@]}"; do
    count=$(grep -c "@ocws_" "$config" 2>/dev/null || echo 0)
    token_usage=$((token_usage + count))
done

if [[ $token_usage -gt 0 ]]; then
    info "Uses $token_usage CSS token references"
else
    warn "No CSS token references found (using hardcoded colors?)"
fi

# Check if tokens.css is included
tokens_included=false
for config in "${config_files[@]}"; do
    if grep -q 'include("tokens.css")' "$config" 2>/dev/null; then
        tokens_included=true
        break
    fi
done

if $tokens_included; then
    pass "tokens.css is included"
else
    warn "tokens.css not included in configs"
fi
echo ""

# ============================================================
# 5. Check for deprecated patterns
# ============================================================
echo "--- Deprecated Patterns ---"
for config in "${config_files[@]}"; do
    cname=$(basename "$config")
    
    # Check for ExecTerm (deprecated)
    if grep -q "ExecTerm" "$config" 2>/dev/null; then
        fail "$cname: Uses deprecated ExecTerm (should use Exec)"
    fi
    
    # Check for hardcoded colors (should use tokens)
    if grep -qE "#[0-9a-fA-F]{6}" "$config" 2>/dev/null; then
        warn "$cname: Contains hardcoded hex colors (consider using tokens)"
    fi
    
    # Check for hardcoded rgba (should use tokens)
    if grep -q "rgba(" "$config" 2>/dev/null; then
        warn "$cname: Contains hardcoded rgba values (consider using tokens)"
    fi
done
echo ""

# ============================================================
# 6. Mode file validation
# ============================================================
echo "--- Mode Files ---"
for mode in "$OCWS_DIR"/*.mode; do
    [[ -f "$mode" ]] || continue
    mname=$(basename "$mode")
    
    info "Mode: $mname"
    
    # Check it includes base.config
    if grep -q 'include("modes/base.config")' "$mode" 2>/dev/null; then
        pass "  Includes base.config"
    else
        warn "  Missing base.config include"
    fi
    
    # Check it includes CSS modules
    css_count=$(grep -c 'include("modes/css-' "$mode" 2>/dev/null || echo 0)
    if [[ $css_count -gt 0 ]]; then
        pass "  Includes $css_count CSS module(s)"
    else
        warn "  No CSS modules included"
    fi
done
echo ""

# ============================================================
# Summary
# ============================================================
echo "=== Results ==="
echo -e "  ${GREEN}Passed: $info_count${NC}"
echo -e "  ${YELLOW}Warnings: $warnings${NC}"
echo -e "  ${RED}Errors: $errors${NC}"
echo ""

if [[ $errors -gt 0 ]]; then
    echo -e "${RED}Some configs have errors. Fix them before deploying.${NC}"
    exit 1
elif [[ $warnings -gt 0 ]]; then
    echo -e "${YELLOW}Some warnings. OCWS will work but review recommended.${NC}"
    exit 0
else
    echo -e "${GREEN}All configs pass validation!${NC}"
    exit 0
fi
