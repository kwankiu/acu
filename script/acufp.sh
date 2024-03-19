# /bin/bash

# Define terminal color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
DEBUG='\033[0;37m'
NC='\033[0m' # No Color

# Echo with colors
colorecho() {
    color="$1"
    text="$2"
    [ -n "$no_warning" ] && [ "$color" = "$YELLOW" ] || [ "$color" = "$DEBUG" ] && [ -z "$debug_log" ] || echo -e "${color}${text}${NC}"
}

################################################################
debug_log=1
# ACU File Pre-Parser
# source: https://github.com/mrbaseman/pasrse_yaml.git
# awk : process multi-line text (handle YAML pipe) (added a space for better syntax / readability)
# sed : replace '-' with a space
pre_parser() {
    local indexfix=-1
    local target_file=$1

    # Handle URL
    if [[ "$target_file" == *"://"* ]]; then
        local temp_file=$(mktemp)
        curl -s "$target_file" > "$temp_file"
        target_file="$temp_file"
    fi

    # Detect awk flavor
    if awk --version 2>&1 | grep -q "GNU Awk" ; then
        # GNU Awk detected
        indexfix=-1
    elif awk -Wv 2>&1 | grep -q "mawk" ; then
        # mawk detected
        indexfix=0
    fi

    local s='[[:space:]]*' sm='[ \t]*' w='[a-zA-Z0-9_.]*' fs=${fs:-$(echo @|tr @ '\034')} i=${i:-  }

    cat $target_file | \
    awk -F$fs "{multi=0;
        if(match(\$0,/$sm\|$sm$/)){multi=1; sub(/$sm\|$sm$/,\" \");}
        if(match(\$0,/$sm>$sm$/)){multi=2; sub(/$sm>$sm$/,\" \");}
        while(multi>0){
            str=\$0; gsub(/^$sm/,\"\", str);
            indent=index(\$0,str);
            indentstr=substr(\$0, 0, indent+$indexfix) \"$i\";
            obuf=\$0;
            getline;
            while(index(\$0,indentstr)){
                obuf=obuf substr(\$0, length(indentstr)+1);
                if (multi==1){obuf=obuf \"\\\\n\";}
                if (multi==2){
                    if(match(\$0,/^$sm$/))
                        obuf=obuf \"\\\\n\";
                        else obuf=obuf \" \";
                }
                getline;
            }
            sub(/$sm$/,\"\",obuf);
            print obuf;
            multi=0;
            if(match(\$0,/$sm\|$sm$/)){multi=1; sub(/$sm\|$sm$/,\"\");}
            if(match(\$0,/$sm>$sm$/)){multi=2; sub(/$sm>$sm$/,\"\");}
        }
    print}" | \
    sed 's/^\( *\)-/\1 /'

    # Remove the temporary file if it was created
    if [[ -n $temp_file ]]; then
        rm "$temp_file"
    fi
}

# ACU File Parser
# Limitation: this is not a full YAML parser, it is only designed to properly handle upto two sub-tree (subhead)
# Limitation: an unnecessary space at line ending can potentially cause issues
load_yaml() {

    local target_file=$1
    local suffix=$2
    local output_format=$3
    local current_head=""
    local current_subhead=""
    local last_indent=""
    local sub_item
    local head_list=()
    local occurrence
    local found_exist

    # Pre-Parse the file or url and generate the formatted YAML output
    target_file="$(pre_parser "$target_file")"

    # Parse the data into variables format
    if [ -f "$target_file" ] || [[ "$target_file" == *"://"* ]] ; then
        while IFS= read -r line; do
            # Ignore comments and empty lines
            if ! [[ $line =~ ^[[:space:]]*($|#) ]]; then
                # Count indentation
                local indentation=$(expr "$line" : '^ *' / 2)
                # Remove indent spaces
                line="${line#"${line%%[![:space:]]*}"}"
                if [ "$indentation" = 0 ]; then
                    current_head="${line/:/}"
                elif [[ "$line" == *":"* ]]; then
                    if [ -z "$suffix" ]; then
                        # Use current head as suffix
                        current_value="${current_head}_"
                    elif [ "$suffix" != " " ]; then
                        # Use user specified suffix
                        current_value="${suffix}_"
                    else
                        # Without suffix
                        current_value=""
                    fi
                    if [ "$output_format" = "list" ]; then
                        found_exist=0
                        current_var=$(awk -F':' '{print $1}' <<< "${current_value}${line}")
                        for item in "${head_list[@]}"; do
                            if [ "$item" = "$current_var" ]; then
                                found_exist=1
                                break
                            fi
                        done
                        if [ "$found_exist" -eq 0 ]; then
                            head_list+=("$current_var")
                            current_value="${current_value}${line//: /=(\"}\")"
                        else
                            current_value="${current_value}${line//: /+=(\"}\")"
                        fi
                    else
                        current_value="${current_value}${line//: /=\"}\""
                    fi
                    # Add variable closing after handling sub_items
                    if [ "$sub_item" = 2 ]; then
                        if [ "$output_format" = "list" ]; then
                            echo "\")"
                        else
                            echo "\""
                        fi
                    fi
                    if [[ "$current_value" != *":\"" ]] && [[ "$current_value" != *":\")" ]]; then
                        echo "$current_value"
                        sub_item=0
                    else
                        current_subhead="${line/:/}"
                        sub_item=1
                    fi
                elif [ "$indentation" -gt "$last_indent" ] || [ "$indentation" == "$last_indent" ]; then
                    if [ -z "$suffix" ]; then
                        # Use current head as suffix
                        current_value="${current_head}_${current_subhead}"
                    elif [ "$suffix" != " " ]; then
                        # Use user specified suffix
                        current_value="${suffix}_${current_subhead}"
                    else
                        # Without suffix
                        current_value="${current_subhead}"
                    fi
                    if [ "$output_format" = "list" ]; then
                        found_exist=0
                        for item in "${head_list[@]}"; do
                            if [ "$item" = "$current_value" ]; then
                                found_exist=1
                                break
                            fi
                        done
                        if [ "$found_exist" -eq 0 ]; then
                            head_list+=("$current_value")
                            current_value="${current_value}=(\"${line}"
                        else
                            current_value="${current_value}+=(\"${line}"
                        fi
                    else
                        current_value="${current_value}=\"${line}"
                    fi
                    if [ "$sub_item" = 1 ]; then
                        echo -n "$current_value"
                        sub_item=2
                    else
                        echo -n " $line"
                    fi
                else
                    colorecho "$DEBUG" "Indent: $indentation, Unhandled Line: $line"
                fi
                last_indent=$indentation
            fi
        done <<< "$target_file"
        # Fix sub_item that appears on the last line
        # Add variable closing after handling sub_items
        if [ "$sub_item" = 2 ]; then
            if [ "$output_format" = "list" ]; then
                    echo "\")"
            else
                    echo "\""
            fi
        fi
    fi
}

set_before=$( set -o posix; set | sed -e '/^_=*/d' )
#eval $(load_yaml "config/config.yaml" " ")
#load_yaml "example/apps.yaml" "" list
#load_yaml "example/apps.yaml"
#load_yaml "config/config.yaml"
load_yaml "$@"

#set_after=$( set -o posix; unset set_before; set | sed -e '/^_=/d' )
#diff  <(echo "$set_before") <(echo "$set_after") | sed -e 's/^> //' -e '/^[[:digit:]].*/d'

