#!/system/bin/sh

# ══════════════════════════════════════════════════════════════════════
#  【全局色彩配置 - Material Design 风格】
# ══════════════════════════════════════════════════════════════════════
C_RES="\033[0m"
C_CYAN="\033[1;36m"
C_YLW="\033[1;33m"
C_GRN="\033[1;32m"
C_RED="\033[1;31m"
C_MAG="\033[1;35m"
C_BLU="\033[1;34m"
C_GRAY="\033[90m"
C_BOLD="\033[1m"
C_DIM="\033[2m"

# ══════════════════════════════════════════════════════════════════════
#  【本地路径与缓存文件初始化】
# ══════════════════════════════════════════════════════════════════════
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
TOKEN_FILE="$SCRIPT_DIR/iclass_token.txt"

# ══════════════════════════════════════
#  【核心用户配置静态区】
# ══════════════════════════════════════
USER="账号"
PASS="密码"  
SCHOOL_ID="62b18d620376d370a0640836"
SERVICE_VERSION="8.0"
BASE="https://pxservice.iclass30.com/gatewayApi"

# ══════════════════════════════════════════════════════════════════════
#  【设备随机化仿真链】
# ══════════════════════════════════════════════════════════════════════
pick() { local lst="$1"; set -- $lst; local idx=$(( $(od -A n -t u1 -N1 /dev/urandom | tr -d ' ') % $# + 1 )); eval echo "\$$idx"; }
rand_hex() { local n="$1" local out=""; while [ ${#out} -lt $n ]; do out="${out}$(dd if=/dev/urandom bs=1 count=4 2>/dev/null | od -A n -t x1 | tr -d ' \n')"; done; echo "${out:0:$n}"; }
rand_letter() { local idx=$(( $(od -A n -t u1 -N1 /dev/urandom | tr -d ' ') % 26 )); printf "\\$(printf '%03o' $((65 + idx)))"; }
rand_u1() { od -A n -t u1 -N1 /dev/urandom | tr -d ' '; }
rand_u2() { od -A n -t u2 -N2 /dev/urandom | tr -d ' '; }

DEV_ID=$(rand_hex 32)
ANDROID_VERS="10 11 12 13 14"
CHROME_MAJORS="120 124 126 130 134 136 138 140 144 147"
BRANDS="SM RMX CPH PHK ONP LE LGE HW NE ACE"
BUILD_PREFIXES="SKQ1 QKQ1 RKQ1 TKQ1 UKQ1"

AV=$(pick "$ANDROID_VERS")
CM=$(pick "$CHROME_MAJORS")
CM_BUILD=$(( $(rand_u2) % 9000 + 1000 ))
CM_PATCH=$(( $(rand_u1) % 200 ))
BRAND=$(pick "$BRANDS")
NUM4=$(( $(rand_u2) % 9000 + 1000 ))
MODEL="${BRAND}${NUM4}$(rand_letter)"
BUILD="$(pick "$BUILD_PREFIXES").$(printf '%02d%02d%02d' $(( $(rand_u1) % 4 + 21 )) $(( $(rand_u1) % 12 + 1 )) $(( $(rand_u1) % 28 + 1 ))).$(( $(rand_u1) % 900 + 100 ))"

UA="Mozilla/5.0 (Linux; Android ${AV}; ${MODEL} Build/${BUILD}; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/${CM}.0.${CM_BUILD}.${CM_PATCH} Mobile Safari/537.36 agentweb/4.$(( $(rand_u1) % 5 )).$(( $(rand_u1) % 10 )) MuKunAPP(android,1,android_student-iclass,com.mukun.c30Online,1.$(( $(rand_u1) % 5 + 1 )).$(( $(rand_u1) % 10 )))"

gp() { echo "$1" | LC_ALL=C grep -a -o "\"$2\":[^,}]*" | head -n1 | sed "s/\"$2\"://" | tr -d '"'; }

# ══════════════════════════════════════════════════════════════════════
#  【身份鉴权控制流与全量看板展示】
# ══════════════════════════════════════════════════════════════════════
do_login() {
    local LOGIN_URL="${BASE}/user/portal/newLoginApp?userName=${USER}&password=${PASS}&deviceId=${DEV_ID}&userId=&versionNumber=1.3.5&sourceType=2&terminalType=app_student&serviceVersion=${SERVICE_VERSION}&schoolId=${SCHOOL_ID}"
    local LOGIN_RES=$(curl -s --connect-timeout 8 --max-time 15 -X GET -H "User-Agent: $UA" "$LOGIN_URL")
    local NEW_TOKEN=$(gp "$LOGIN_RES" "token")
    if [ -n "$NEW_TOKEN" ] && [ "$NEW_TOKEN" != "null" ]; then
        echo -n "$NEW_TOKEN" > "$TOKEN_FILE"
        echo "$NEW_TOKEN"
    else
        echo "ERROR"
    fi
}

TOKEN=""
LOGIN_STATUS="${C_YLW}[读取缓存]${C_RES}"
if [ -f "$TOKEN_FILE" ]; then TOKEN=$(cat "$TOKEN_FILE" | tr -d ' \n'); fi
if [ -z "$TOKEN" ]; then
    LOGIN_STATUS="${C_CYAN}[首次登录]${C_RES}"
    TOKEN=$(do_login)
    if [ "$TOKEN" = "ERROR" ]; then echo -e "${C_RED}[-] 核心登录验证鉴权失败，请检查账号密码。${C_RES}"; exit 1; fi
fi

request_info() {
    local POST_DATA="token=${1}&serviceVersion=${SERVICE_VERSION}&schoolId=${SCHOOL_ID}"
    curl -s --connect-timeout 8 --max-time 15 -X POST -H "token: ${1}" -H "content-type: application/x-www-form-urlencoded" -H "user-agent: $UA" -d "$POST_DATA" "${BASE}/user/user/getMyInfo"
}

INFO_RES=$(request_info "$TOKEN")
CODE=$(gp "$INFO_RES" "code")
if [ "$CODE" != "200" ]; then
    echo -e "${C_RED}[!] 提示: 缓存的 Token 已失效。正在尝试重新握手登录...${C_RES}"
    rm -f "$TOKEN_FILE"
    TOKEN=$(do_login)
    if [ "$TOKEN" = "ERROR" ]; then echo -e "${C_RED}[-] 二次重新登录失败。${C_RES}"; exit 1; fi
    INFO_RES=$(request_info "$TOKEN")
fi

# ======================== 超级美化输出区域 ========================
# 头部横幅
echo -e "\n${C_BOLD}${C_CYAN}╔══════════════════════════════════════════════════════════════════════╗${C_RES}"
echo -e "${C_BOLD}${C_CYAN}║                    📱 iClass 智慧学习系统                            ║${C_RES}"
echo -e "${C_BOLD}${C_CYAN}╚══════════════════════════════════════════════════════════════════════╝${C_RES}\n"

# 登录状态卡片
echo -e "${C_BOLD}🔐 身份验证中心${C_RES}"
echo -e "${C_GRAY}┌─────────────────────────────────────────────────────────────────────┐${C_RES}"
printf " ${C_BOLD}状态${C_RES}       : %b\n" "$LOGIN_STATUS"
printf " ${C_BOLD}Token路径${C_RES}   : ${C_DIM}%s${C_RES}\n" "$TOKEN_FILE"
printf " ${C_BOLD}Session ID${C_RES}  : ${C_GRN}%s${C_RES}\n" "$TOKEN"
echo -e "${C_GRAY}└─────────────────────────────────────────────────────────────────────┘${C_RES}\n"

DISPLAY_NAME=$(gp "$INFO_RES" "displayName")
USER_NAME_RES=$(gp "$INFO_RES" "userName")
SEX=$(gp "$INFO_RES" "sex")
EMP_NUM=$(gp "$INFO_RES" "employeeNumber")
SCHOOL_NAME=$(gp "$INFO_RES" "schoolName")
USER_ID=$(gp "$INFO_RES" "id")

# 用户信息卡片
echo -e "${C_BOLD}👤 个人档案${C_RES}"
echo -e "${C_GRAY}┌─────────────────────────────────────────────────────────────────────┐${C_RES}"
printf " ${C_BOLD}姓名${C_RES}       : ${C_YLW}%s${C_RES}\n" "$DISPLAY_NAME"
printf " ${C_BOLD}账号${C_RES}       : ${C_YLW}%s${C_RES}\n" "$USER_NAME_RES"
printf " ${C_BOLD}性别${C_RES}       : %s\n" "$SEX"
printf " ${C_BOLD}学号/工号${C_RES}  : %s\n" "$EMP_NUM"
printf " ${C_BOLD}学校${C_RES}       : ${C_MAG}%s${C_RES}\n" "$SCHOOL_NAME"
printf " ${C_BOLD}用户ID${C_RES}     : ${C_DIM}%s${C_RES}\n" "$USER_ID"
echo -e "${C_GRAY}└─────────────────────────────────────────────────────────────────────┘${C_RES}\n"

JSON_DATA="{\"stuId\":\"${USER_ID}\",\"page\":1,\"courseName\":\"\",\"courseState\":1,\"openCourseName\":\"\",\"pageSize\":100,\"categoryType\":0}"
COURSE_RES=$(curl -s --connect-timeout 8 --max-time 15 -X POST -H "content-type: application/json" -H "token: $TOKEN" -H "user-agent: $UA" -d "$JSON_DATA" "${BASE}/course/stuCourse/getStuCourseList")

# ══════════════════════════════════════════════════════════════════════
#  【核心秒刷引擎】 —— 优雅改良：彻底切断已完结课件的二次触发
# ══════════════════════════════════════════════════════════════════════
execute_auto_brush() {
    local c_id="$1" local o_c_id="$2" local cell_id="$3" local up_mod_id="$4" local c_type="$5" local cell_name="$6"
    
    (
        local PREVIEW_URL="${BASE}/design/stuCell/getCellPreviewByStu?cellId=${cell_id}&openCourseId=${o_c_id}&courseId=${c_id}&upModuleId=${up_mod_id}"
        local PREVIEW_RES=$(curl -s --connect-timeout 8 --max-time 15 -X GET -H "token: $TOKEN" -H "User-Agent: $UA" "$PREVIEW_URL")
        
        local T_ID=$(gp "$PREVIEW_RES" "tokenId")
        [ -z "$T_ID" ] || [ "$T_ID" = "null" ] && return
        
        local SAVE_URL=""
        local RAND_OFFSET=$(( ( $(rand_u1) % 41 ) + 10 ))

        if [ "$c_type" = "ppt" ]; then
            local MAX_PAGE=$(( ( $(rand_u1) % 61 ) + 110 ))
            local CALC_TIME=$(( (MAX_PAGE * 3) + RAND_OFFSET ))
            
            echo -e "        ${C_YLW}⚡ [PPT智能穿透] -> 《${cell_name}》 (${MAX_PAGE}页)${C_RES}"
            
            SAVE_URL="${BASE}/design/study/saveStudyCellInfo?courseId=${c_id}&openCourseId=${o_c_id}&cellId=${cell_id}&studyTime=${CALC_TIME}&studyVideoMaxTime=0&studyMaxPage=${MAX_PAGE}&videoTimeTotalLong=0&tokenId=${T_ID}"
        else
            local DURATION_RAW=$(echo "$PREVIEW_RES" | sed -n 's/.*"duration":"\([0-9.]*\)".*/\1/p')
            local DURATION=0
            [ -n "$DURATION_RAW" ] && DURATION=$(printf "%.0f" "$DURATION_RAW" 2>/dev/null)
            
            if [ -z "$DURATION" ] || [ "$DURATION" -eq 0 ]; then
                local V_STUDY_TIME=$(( 1000 + RAND_OFFSET ))
                DURATION=$V_STUDY_TIME
            else
                local V_RAND=$(( ( $(rand_u1) % 5 ) + 5 ))
                local V_STUDY_TIME=$(( DURATION + V_RAND ))
            fi
            SAVE_URL="${BASE}/design/study/saveStudyCellInfo?courseId=${c_id}&openCourseId=${o_c_id}&cellId=${cell_id}&studyTime=${V_STUDY_TIME}&studyVideoMaxTime=${DURATION}&studyMaxPage=1&videoTimeTotalLong=${DURATION}&tokenId=${T_ID}"
        fi

        curl -s --connect-timeout 8 --max-time 15 -X GET -H "token: $TOKEN" -H "User-Agent: $UA" "$SAVE_URL" > /dev/null
    ) & 
}

# ══════════════════════════════════════════════════════════════════════
#  【纯净型树状解析器】
# ══════════════════════════════════════════════════════════════════════
parse_tree_node() {
    local c_id="$1" local o_c_id="$2" local p_id="$3" local m_id="$4" local c_level="$5" local indent="$6"
    
    local API_URL="${BASE}/design/stuCell/getCellListByStu?courseId=${c_id}&openCourseId=${o_c_id}&parentId=${p_id}&moduleId=${m_id}&cellLevel=${c_level}&stuId=${USER_ID}"
    local NODE_RES=$(curl -s --connect-timeout 8 --max-time 15 -X GET -H "token: $TOKEN" -H "User-Agent: $UA" "$API_URL")
    local RAW_NODES=$(echo "$NODE_RES" | LC_ALL=C grep -a -o '{"id":"[^"]*"[^}]*}')
    
    [ -z "$RAW_NODES" ] && return
    
    local PRE_SORTED=""
    local old_ifs="$IFS"
    IFS=$'\n'
    for node_line in $RAW_NODES; do
        [ -z "$node_line" ] && continue
        local N_ID=$(echo "$node_line" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')
        local N_NAME=$(echo "$node_line" | sed -n 's/.*"cellName":"\([^"]*\)".*/\1/p')
        local N_TYPE=$(echo "$node_line" | sed -n 's/.*"cellType":\([0-9]*\).*/\1/p')
        local N_LEVEL=$(echo "$node_line" | sed -n 's/.*"cellLevel":\([0-9]*\).*/\1/p')
        local N_PROC=$(echo "$node_line" | sed -n 's/.*"cellProcess":\([0-9.]*\).*/\1/p')
        local N_CAT=$(echo "$node_line" | sed -n 's/.*"categoryName":"\([^"]*\)".*/\1/p')
        local N_ORDER=$(echo "$node_line" | sed -n 's/.*"sortOrder":\([0-9]*\).*/\1/p')
        
        [ -z "$N_ORDER" ] && N_ORDER="999"
        [ -z "$N_NAME" ] && continue
        [ -z "$N_PROC" ] && N_PROC="0"
        
        PRE_SORTED="${PRE_SORTED}${N_ORDER}|${N_ID}|${N_NAME}|${N_TYPE}|${N_LEVEL}|${N_PROC}|${N_CAT}\n"
    done
    IFS="$old_ifs"
    
    local SORTED_NODES=$(echo -e "$PRE_SORTED" | LC_ALL=C grep -a -v '^$' | sort -t'|' -k1,1n)
    local TOTAL_COUNT=$(echo "$SORTED_NODES" | LC_ALL=C grep -a -v '^$' | wc -l)
    local CURRENT_COUNT=0
    
    old_ifs="$IFS"
    IFS=$'\n'
    for item in $SORTED_NODES; do
        [ -z "$item" ] && continue
        CURRENT_COUNT=$((CURRENT_COUNT + 1))
        
        local id=$(echo "$item" | cut -d'|' -f2)
        local name=$(echo "$item" | cut -d'|' -f3)
        local ctype=$(echo "$item" | cut -d'|' -f4)
        local clevel=$(echo "$item" | cut -d'|' -f5)
        local proc=$(echo "$item" | cut -d'|' -f6)
        local cat=$(echo "$item" | cut -d'|' -f7)
        
        local TREE_BRANCH="├── "
        local NEXT_INDENT="${indent}│   "
        if [ "$CURRENT_COUNT" -eq "$TOTAL_COUNT" ]; then
            TREE_BRANCH="└── "
            NEXT_INDENT="${indent}    "
        fi
        
        if [ "$ctype" -eq 4 ] || [ "$clevel" -le 2 ] || [ -z "$cat" ]; then
            printf "%b%s📁 %b%s%b\n" "$indent" "$TREE_BRANCH" "$C_YLW" "$name" "$C_RES"
            parse_tree_node "$c_id" "$o_c_id" "$id" "$m_id" 3 "$NEXT_INDENT"
        else
            local TYP_ICON="📄"
            local SIM_CAT="ppt"
            if [ "$cat" = "视频" ] || echo "$name" | LC_ALL=C grep -a -qEi "\.(mp4|mkv|avi|flv)$"; then
                TYP_ICON="🎬"
                SIM_CAT="video"
            fi
            
            printf "%b%s %b %s %b-> 进度: ${C_GRN}%s%%${C_RES}\n" "$indent" "$TREE_BRANCH" "$TYP_ICON" "$name" "$C_DIM" "$proc"
            
            if [ "$proc" != "100" ] && [ "$proc" != "100.0" ]; then
                execute_auto_brush "$c_id" "$o_c_id" "$id" "${p_id:-$m_id}" "$SIM_CAT" "$name"
            fi
        fi
    done
    IFS="$old_ifs"
}

# ══════════════════════════════════════════════════════════════════════
#  【核心主控制流循环】
# ══════════════════════════════════════════════════════════════════════
echo -e "${C_BOLD}📚 我的课程表${C_RES}"
echo -e "${C_GRAY}┌─────────────────────────────────────────────────────────────────────┐${C_RES}"

COURSE_COUNT=0
echo "$COURSE_RES" | LC_ALL=C grep -a -o '{"id":"[^"]*"[^}]*}' | while read -r line; do
    
    C_ID=$(echo "$line" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')
    C_NAME=$(echo "$line" | sed -n 's/.*"courseName":"\([^"]*\)".*/\1/p')
    RAW_COURSE_ID=$(echo "$line" | sed -n 's/.*"courseId":"\([^"]*\)".*/\1/p')
    RAW_OPEN_COURSE_ID=$(echo "$line" | sed -n 's/.*"openCourseId":"\([^"]*\)".*/\1/p')
    
    [ -z "$C_NAME" ] && continue

    MODULE_URL="${BASE}/design/stuCell/getOpenCourseModuleByStu?courseId=${RAW_COURSE_ID}&openCourseId=${RAW_OPEN_COURSE_ID}"
    MODULE_RES=$(curl -s --connect-timeout 8 --max-time 15 -X GET -H "token: $TOKEN" -H "user-agent: $UA" "$MODULE_URL")

    if echo "$MODULE_RES" | LC_ALL=C grep -a -q '"status"\|"error"'; then
        ERR_MSG=$(echo "$MODULE_RES" | sed -n 's/.*"error":"\([^"]*\)".*/\1/p')
        ERR_STAT=$(echo "$MODULE_RES" | sed -n 's/.*"status":\([0-9]*\).*/\1/p')
        if [ "$ERR_STAT" = "500" ] || [ -n "$ERR_MSG" ]; then
            echo -e "  📖 ${C_CYAN}${C_NAME}${C_RES}"
            echo -e "     ${C_RED}⚠️ 章节拉取失败 [HTTP ${ERR_STAT:-未知}]${C_RES}"
            echo -e "     ${C_DIM}${ERR_MSG:-"未知异常"}${C_RES}"
            echo -e "${C_GRAY}  ────────────────────────────────────────────────────────────────${C_RES}"
            continue
        fi
    fi

    RAW_MOD_LINES=$(echo "$MODULE_RES" | LC_ALL=C grep -a -o '{"moduleId":"[^"]*"[^}]*}')
    if [ -z "$RAW_MOD_LINES" ]; then
        echo -e "  📖 ${C_CYAN}${C_NAME}${C_RES} ${C_DIM}[暂无章节内容]${C_RES}"
        echo -e "${C_GRAY}  ────────────────────────────────────────────────────────────────${C_RES}"
        continue
    fi

    T_NAME=$(echo "$line" | sed -n 's/.*"mainTeacherName":"\([^"]*\)".*/\1/p')
    C_PROC=$(echo "$line" | sed -n 's/.*"process":\([0-9.]*\).*/\1/p')
    C_SCORE=$(echo "$line" | sed -n 's/.*"stuScore":\([0-9.]*\).*/\1/p')

    [ -z "$C_PROC" ] && C_PROC="0"
    [ -z "$C_SCORE" ] && C_SCORE="0.0"
    [ -z "$T_NAME" ] && T_NAME="未知教师"

    echo -e "  📖 ${C_BOLD}${C_NAME}${C_RES}"
    echo -e "     👨‍🏫 ${T_NAME}  |  📊 进度 ${C_GRN}${C_PROC}%${C_RES}  |  💯 成绩 ${C_YLW}${C_SCORE}${C_RES}"
    echo -e "     ${C_DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RES}"

    echo "$RAW_MOD_LINES" | while read -r mod_line; do
        M_ID=$(echo "$mod_line" | sed -n 's/.*"moduleId":"\([^"]*\)".*/\1/p')
        M_NAME=$(echo "$mod_line" | sed -n 's/.*"moduleName":"\([^"]*\)".*/\1/p')
        M_TOTAL=$(echo "$mod_line" | sed -n 's/.*"cellCount":\([0-9]*\).*/\1/p')
        M_FINISH=$(echo "$mod_line" | sed -n 's/.*"stuFinishCellCount":\([0-9]*\).*/\1/p')
        M_LOCK=$(echo "$mod_line" | sed -n 's/.*"isLock":\([0-9]*\).*/\1/p')
        M_ORDER=$(echo "$mod_line" | sed -n 's/.*"sortOrder":\([0-9]*\).*/\1/p')
        
        [ -z "$M_ORDER" ] && M_ORDER="999"
        [ -z "$M_NAME" ] && continue
        echo "${M_ORDER}|${M_ID}|${M_NAME}|${M_TOTAL}|${M_FINISH}|${M_LOCK}"
    done | sort -t'|' -k1,1n | while read -r mod_sort_line; do
        [ -z "$mod_sort_line" ] && continue
        id=$(echo "$mod_sort_line" | cut -d'|' -f2)
        name=$(echo "$mod_sort_line" | cut -d'|' -f3)
        total=$(echo "$mod_sort_line" | cut -d'|' -f4)
        finish=$(echo "$mod_sort_line" | cut -d'|' -f5)
        lock=$(echo "$mod_sort_line" | cut -d'|' -f6)
        
        [ -z "$total" ] && total=0
        [ -z "$finish" ] && finish=0
        [ -z "$lock" ] && lock=0

        if [ "$total" -eq 0 ]; then
            M_STATUS="${C_GRN}○ 无课件${C_RES}"
        elif [ "$total" -gt 0 ] && [ "$finish" -eq "$total" ]; then
            M_STATUS="${C_GRN}✓ 已学完${C_RES}"
        elif [ "$lock" -eq 1 ]; then
            M_STATUS="${C_RED}🔒 未解锁${C_RES}"
        else
            M_STATUS="${C_YLW}▶ 学习中${C_RES}"
        fi
        
        echo -e "     ├─ 📂 ${name} ${M_STATUS} (${finish}/${total})"
        
        if [ "$total" -eq 0 ] || [ "$finish" -eq "$total" ] || [ "$lock" -eq 1 ]; then continue; fi
        
        parse_tree_node "$RAW_COURSE_ID" "$RAW_OPEN_COURSE_ID" "" "$id" 2 "     │  "
        
    done
    echo -e "${C_GRAY}  ────────────────────────────────────────────────────────────────${C_RES}"
done

echo -e "${C_GRAY}└─────────────────────────────────────────────────────────────────────┘${C_RES}\n"

wait

# ══════════════════════════════════════════════════════════════════════
#  【战果汇总离线看板】—— Material Design 风格收官
# ══════════════════════════════════════════════════════════════════════
echo -e "${C_BOLD}${C_CYAN}╔══════════════════════════════════════════════════════════════════════╗${C_RES}"
echo -e "${C_BOLD}${C_CYAN}║                      🎉 本次学习任务报告                              ║${C_RES}"
echo -e "${C_BOLD}${C_CYAN}╠══════════════════════════════════════════════════════════════════════╣${C_RES}"
echo -e "${C_BOLD}${C_CYAN}║${C_RES}  ${C_GRN}✔${C_RES}  所有未完结课件已提交后台处理                              ${C_BOLD}${C_CYAN}║${C_RES}"
echo -e "${C_BOLD}${C_CYAN}║${C_RES}  ${C_YLW}⚡${C_RES}  PPT智能防锁死引擎已激活（仅针对未完结课件）                ${C_BOLD}${C_CYAN}║${C_RES}"
echo -e "${C_BOLD}${C_CYAN}║${C_RES}  ${C_DIM}ℹ️${C_RES}  已学完课件保持静默，数据同步存在延迟，请稍后刷新网页查看    ${C_BOLD}${C_CYAN}║${C_RES}"
echo -e "${C_BOLD}${C_CYAN}╚══════════════════════════════════════════════════════════════════════╝${C_RES}\n"
