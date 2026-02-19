get_status() {
    printf "Antiscan Version:\t${BOLD_TEXT}$ASCN_VERSION${NO_STYLE}\n"
    printf "Status:\t\t\t"
    if ascn_is_running; then
        if config_is_reloading; then
            printf "${YELLOW_COLOR}updating configuration${NO_STYLE}\n"
        elif geo_is_loading; then
            printf "${YELLOW_COLOR}updating country subnet lists${NO_STYLE}\n"
        else
            if all_protections_disabled; then
                printf "${YELLOW_COLOR}protection disabled${NO_STYLE}\n"
            else
                printf "${GREEN_COLOR}running${NO_STYLE}\n"
            fi

            if [ "$ENABLE_IPS_BAN" == "1" ]; then
                local banned_ip_count="$(ipset list ascn_ips | tail -n +8 | grep -c '^')"
                local banned_subnets_count="$(ipset list ascn_subnets | tail -n +8 | grep -c '^')"
                printf "Blocked addresses:\t${BOLD_TEXT}$banned_ip_count${NO_STYLE}\n"
                printf "Blocked subnets:\t${BOLD_TEXT}$banned_subnets_count${NO_STYLE}\n"
            else
                printf "IP/Subnet blocking:\t${RED_COLOR}disabled${NO_STYLE}\n"
            fi

            if [ "$ENABLE_HONEYPOT" == "1" ]; then
                local banned_ip_honeypot_count="$(ipset list ascn_honeypot | tail -n +8 | grep -c '^')"
                printf "Blocked by honeypot:\t${BOLD_TEXT}$banned_ip_honeypot_count${NO_STYLE}\n"
            else
                printf "Honeypot blocking:\t${RED_COLOR}disabled${NO_STYLE}\n"
            fi

            if [ "$READ_NDM_LOCKOUT_IPSETS" == "1" ]; then
                local banned_ip_ndm_count="$(ipset list ascn_ndm_lockout | tail -n +8 | grep -c '^')"
                printf "Blocked by NDMS:\t${BOLD_TEXT}$banned_ip_ndm_count${NO_STYLE}\n"
            else
                printf "NDMS list reading:\t${RED_COLOR}disabled${NO_STYLE}\n"
            fi

            if [ "$USE_CUSTOM_EXCLUDE_LIST" == "1" ] || [ "$CUSTOM_LISTS_BLOCK_MODE" == "blacklist" ] || [ "$CUSTOM_LISTS_BLOCK_MODE" == "whitelist" ]; then
                if [ "$USE_CUSTOM_EXCLUDE_LIST" == "1" ]; then
                    local excluded_count="$(ipset -q list ascn_custom_exclude | tail -n +8 | grep -c '^')"
                    if [ "$excluded_count" -gt 0 ]; then
                        printf "Exclusion list:\t\t${BOLD_TEXT}$(get_ipset_member_text "$excluded_count")${NO_STYLE}\n"
                    else
                        printf "Exclusion list:\t\t${RED_COLOR}inactive${NO_STYLE}\n"
                    fi
                fi

                case "$CUSTOM_LISTS_BLOCK_MODE" in
                "blacklist" | "whitelist")
                    local custom_set_name="ascn_custom_${CUSTOM_LISTS_BLOCK_MODE}"
                    local custom_set_type=""
                    [ "$CUSTOM_LISTS_BLOCK_MODE" == "blacklist" ] && custom_set_type="Blacklist" || custom_set_type="Whitelist"
                    local custom_ip_count="$(ipset -q list $custom_set_name | tail -n +8 | grep -c '^')"
                    if [ "$custom_ip_count" -gt 0 ]; then
                        printf "${custom_set_type}:\t\t${BOLD_TEXT}$(get_ipset_member_text "$custom_ip_count")${NO_STYLE}\n"
                    else
                        printf "${custom_set_type}:\t\t${RED_COLOR}inactive${NO_STYLE}\n"
                    fi
                    ;;
                esac
            else
                printf "Custom lists\t\t${RED_COLOR}inactive${NO_STYLE}\n"
            fi

            printf "Geoblocking mode:\t"
            case "$GEOBLOCK_MODE" in
            "blacklist" | "whitelist")
                local geoset_name="ascn_geo_${GEOBLOCK_MODE}"
                local geoset_type=""
                [ "$GEOBLOCK_MODE" == "blacklist" ] && geoset_type="blacklist" || geoset_type="whitelist"

                local geo_directory="$IPSETS_DIRECTORY/geo"
                local available_countries_list=""
                local countries_list=""
                if [ ! -d "$geo_directory" ]; then
                    countries_list="${RED_COLOR}${GEOBLOCK_COUNTRIES}${NO_STYLE}"
                else
                    for country in $GEOBLOCK_COUNTRIES; do
                        local subnets_file="$geo_directory/$country.txt"
                        if [ ! -s "$subnets_file" ]; then
                            [ -z "$countries_list" ] && countries_list="${RED_COLOR}${country}${NO_STYLE}" || countries_list="${countries_list} ${RED_COLOR}${country}${NO_STYLE}"
                        else
                            [ -z "$available_countries_list" ] && available_countries_list="${country}" || available_countries_list="${available_countries_list} ${country}"
                            [ -z "$countries_list" ] && countries_list="${BOLD_TEXT}${country}${NO_STYLE}" || countries_list="${countries_list} ${BOLD_TEXT}${country}${NO_STYLE}"
                        fi
                    done
                fi

                if [ -n "$(ipset -q -n list $geoset_name)" ] && [ -n "$available_countries_list" ]; then
                    printf "${GREEN_COLOR}$geoset_type${NO_STYLE}\n"
                else
                    printf "${RED_COLOR}not working${NO_STYLE}\n"
                fi
                printf "Geoblocking countries:\t${countries_list}\n"
                ;;
            *)
                printf "${RED_COLOR}отключена${NO_STYLE}\n"
                ;;
            esac

            printf "Country exclusions:\t"
            if [ -n "$GEO_EXCLUDE_COUNTRIES" ]; then
                local geo_directory="$IPSETS_DIRECTORY/geo"
                local available_countries_list=""
                local countries_list=""
                if [ ! -d "$geo_directory" ]; then
                    countries_list="${RED_COLOR}${GEO_EXCLUDE_COUNTRIES}${NO_STYLE}"
                else
                    for country in $GEO_EXCLUDE_COUNTRIES; do
                        local subnets_file="$geo_directory/$country.txt"
                        if [ ! -s "$subnets_file" ]; then
                            [ -z "$countries_list" ] && countries_list="${RED_COLOR}${country}${NO_STYLE}" || countries_list="${countries_list} ${RED_COLOR}${country}${NO_STYLE}"
                        else
                            [ -z "$available_countries_list" ] && available_countries_list="${country}" || available_countries_list="${available_countries_list} ${country}"
                            [ -z "$countries_list" ] && countries_list="${BOLD_TEXT}${country}${NO_STYLE}" || countries_list="${countries_list} ${BOLD_TEXT}${country}${NO_STYLE}"
                        fi
                    done
                fi
                printf "${countries_list}\n"
            else
                printf "${RED_COLOR}disabled${NO_STYLE}\n"
            fi
        fi
    else
        printf "${RED_COLOR}не запущен${NO_STYLE}\n"
    fi
}

get_ipset_member_text() {
    local record="records"
    case $1 in
    *1?) true ;;
    *[2-4]) record="entries" ;;
    *1) record="entry" ;;
    esac
    echo "$1 $record"
}}

show_ipsets() {
    case "$1" in
    ips | subnets | ndm_lockout | honeypot)
        if ascn_is_running; then
            if config_is_reloading; then
                print_message "error" "Data viewing is not available during Antiscan configuration update"
            else
                local text="addresses"
                local text_1="addresses"
                if [ "$1" == "subnets" ]; then
                    text="subnets"
                    text_1="subnets"
                fi
                local ipset_data="$(ipset -q list ascn_$1 -s | tail -n +8)"
                local banned_count=0
                [ -n "$ipset_data" ] && banned_count="$(echo "$ipset_data" | grep -c '^')"
                if [ "$banned_count" -eq 0 ]; then
                    print_message "console" "No blocked ${text} found"
                else
                    print_message "console" "Blocked ${text}:"
                    echo "$ipset_data"
                    print_message "console" "Blocked ${text_1}: ${banned_count}"
                fi
            fi
        else
            print_message "error" "Antiscan is not running"
        fi
        ;;
    *)
        print_message "console" "Usage: $0 list {ips|subnets|ndm_lockout|honeypot}"
        ;;
    esac
}

show_version() {
    if [ "$1" == "opkg" ]; then
        local ascn_opkg_version="$(opkg list-installed antiscan | awk '{print $3}')"
        if [ -z "$ascn_opkg_version" ]; then
            print_message "console" "Failed to determine Antiscan package version"
        else
            print_message "console" "Antiscan Version (OPKG): $ascn_opkg_version"
        fi
    else
        print_message "console" "Antiscan Version: $ASCN_VERSION"
    fi
}
