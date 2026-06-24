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
TMP_SORT_FILE="/data/local/tmp/iclass_sort.tmp"
rm -f "$TMP_SORT_FILE"

# ══════════════════════════════════════════════════════════════════════
#  【核心工具函数 终极安全版】
# ══════════════════════════════════════════════════════════════════════
# 仅提取数字与小数点，返回纯数字字符串
to_num() {
    local val="$1"
    val=$(echo "$val" | tr -cd '0-9.')
    if [ -z "$val" ] || [ "$val" = "." ]; then
        echo 0
    else
        echo "$val"
    fi
}

# 安全随机数字，兜底防空、杜绝非数字输出
rand() {
    local max="$1"
    local raw=$(dd if=/dev/urandom bs=1 count=2 2>/dev/null | od -An -tu2 | tr -cd '0-9')
    [ -z "$raw" ] && raw="1234"
    local num=$(( raw % max ))
    echo "$num"
}

# 从列表随机选一项，只输出文本
pick() {
    local lst="$1"
    set -- $lst
    local r=$(rand 10000)
    local idx=$(( r % $# + 1 ))
    eval printf '%s' "\$$idx"
}

# 仅生成十六进制文本，全程不进任何数值运算
rand_hex() {
    local n="$1"
    local out=""
    while [ ${#out} -lt $n ]; do
        seg=$(dd if=/dev/urandom bs=1 count=4 2>/dev/null | od -An -tx1 | tr -d ' \n')
        out="${out}${seg}"
    done
    printf '%s' "${out:0:$n}"
}

# 随机大写字母文本
rand_letter() {
    local r=$(rand 26)
    printf "\\$(printf '%03o' $((65 + r)))"
}

# JSON字段提取，纯字符串输出
gp() {
    echo "$1" | LC_ALL=C grep -a -o "\"$2\":[^,}]*" | head -n1 | sed "s/\"$2\"://" | tr -d '"'
}

# ══════════════════════════════════
#  【核心用户配置静态区】
# ══════════════════════════════════
USER="账号"
PASS="密码"
SCHOOL_ID="62b18d620376d370a0640836"
SERVICE_VERSION="8.0"
BASE="https://pxservice.iclass30.com/gatewayApi"

# ══════════════════════════════════════════════════════════════════════
#  【设备随机化仿真链 文本/数字完全隔离】
# ══════════════════════════════════════════════════════════════════════
DEV_ID_TEXT=$(rand_hex 32)

ANDROID_VERS="10 11 12 13 14"
CHROME_MAJORS="120 124 126 130 134 136 138 140 144 147"
BRANDS="SM RMX CPH PHK ONP LE LGE HW NE ACE"
BUILD_PREFIXES="SKQ1 QKQ1 RKQ1 TKQ1 UKQ1"

AV_TEXT=$(pick "$ANDROID_VERS")
CM_MAJOR_TEXT=$(pick "$CHROME_MAJORS")
CM_BUILD_NUM=$(( $(rand 9000) + 1000 ))
CM_PATCH_NUM=$(rand 200)
BRAND_TEXT=$(pick "$BRANDS")
NUM4_NUM=$(( $(rand 9000) + 1000 ))
RAND_CHAR_TEXT=$(rand_letter)
MODEL_TEXT="${BRAND_TEXT}${NUM4_NUM}${RAND_CHAR_TEXT}"

BUILD_PRE_TEXT=$(pick "$BUILD_PREFIXES")
YEAR_NUM=$(( $(rand 4) + 21 ))
MONTH_NUM=$(( $(rand 12) + 1 ))
DAY_NUM=$(( $(rand 28) + 1 ))
BUILD_SUF_NUM=$(( $(rand 900) + 100 ))
BUILD_TEXT="${BUILD_PRE_TEXT}.$(printf '%02d%02d%02d' $YEAR_NUM $MONTH_NUM $DAY_NUM).${BUILD_SUF_NUM}"

UA_TEXT="Mozilla/5.0 (Linux; Android ${AV_TEXT}; ${MODEL_TEXT} Build/${BUILD_TEXT}; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/${CM_MAJOR_TEXT}.0.${CM_BUILD_NUM}.${CM_PATCH_NUM} Mobile Safari/537.36 agentweb/4.$(rand 5).$(rand 10) MuKunAPP(android,1,android_student-iclass,com.mukun.c30Online,1.$(( $(rand 5) + 1 )).$(rand 10))"

# ══════════════════════════════════════════════════════════════════════
#  【身份鉴权控制流】
# ══════════════════════════════════════════════════════════════════════
do_login() {
    local LOGIN_URL="${BASE}/user/portal/newLoginApp?userName=${USER}&password=${PASS}&deviceId=${DEV_ID_TEXT}&userId=&versionNumber=1.3.5&sourceType=2&terminalType=app_student&serviceVersion=${SERVICE_VERSION}&schoolId=${SCHOOL_ID}"
    local LOGIN_RES=$(curl -s --connect-timeout 8 --max-time 15 -X GET -H "User-Agent: $UA_TEXT" "$LOGIN_URL")
    local NEW_TOKEN_TEXT=$(gp "$LOGIN_RES" "token")
    if [ -n "$NEW_TOKEN_TEXT" ] && [ "$NEW_TOKEN_TEXT" != "null" ]; then
        echo -n "$NEW_TOKEN_TEXT" > "$TOKEN_FILE"
        printf '%s' "$NEW_TOKEN_TEXT"
    else
        printf 'ERROR'
    fi
}

TOKEN_TEXT=""
LOGIN_STATUS="${C_YLW}[读取缓存]${C_RES}"
if [ -f "$TOKEN_FILE" ]; then TOKEN_TEXT=$(cat "$TOKEN_FILE" | tr -d ' \n'); fi
if [ -z "$TOKEN_TEXT" ]; then
    LOGIN_STATUS="${C_CYAN}[首次登录]${C_RES}"
    TOKEN_TEXT=$(do_login)
    if [ "$TOKEN_TEXT" = "ERROR" ]; then echo -e "${C_RED}[-] 核心登录验证鉴权失败，请检查账号密码。${C_RES}"; exit 1; fi
fi

request_info() {
    local POST_DATA="token=${1}&serviceVersion=${SERVICE_VERSION}&schoolId=${SCHOOL_ID}"
    curl -s --connect-timeout 8 --max-time 15 -X POST -H "token: ${1}" -H "content-type: application/x-www-form-urlencoded" -H "user-agent: $UA_TEXT" -d "$POST_DATA" "${BASE}/user/user/getMyInfo"
}

INFO_RES=$(request_info "$TOKEN_TEXT")
CODE_RAW=$(gp "$INFO_RES" "code")
CODE_NUM=$(to_num "$CODE_RAW")
if [ "$CODE_NUM" != "200" ]; then
    echo -e "${C_RED}[!] 提示: 缓存的 Token 已失效。正在尝试重新握手登录...${C_RES}"
    rm -f "$TOKEN_FILE"
    TOKEN_TEXT=$(do_login)
    if [ "$TOKEN_TEXT" = "ERROR" ]; then echo -e "${C_RED}[-] 二次重新登录失败。${C_RES}"; exit 1; fi
    INFO_RES=$(request_info "$TOKEN_TEXT")
fi

# ======================== 美化输出 ========================
echo -e "\n${C_BOLD}${C_CYAN}╔══════════════════════════════════════════════════════════════════════╗${C_RES}"
echo -e "${C_BOLD}${C_CYAN}║                    📱 iClass 智慧学习系统                            ║${C_RES}"
echo -e "${C_BOLD}${C_CYAN}╚══════════════════════════════════════════════════════════════════════╝${C_RES}\n"

echo -e "${C_BOLD}🔐 身份验证中心${C_RES}"
echo -e "${C_GRAY}┌─────────────────────────────────────────────────────────────────────┐${C_RES}"
printf " ${C_BOLD}状态${C_RES}       : %b\n" "$LOGIN_STATUS"
printf " ${C_BOLD}Token路径${C_RES}   : ${C_DIM}%s${C_RES}\n" "$TOKEN_FILE"
printf " ${C_BOLD}Session ID${C_RES}  : ${C_GRN}%s${C_RES}\n" "$TOKEN_TEXT"
echo -e "${C_GRAY}└─────────────────────────────────────────────────────────────────────┘${C_RES}\n"

DISPLAY_NAME_TEXT=$(gp "$INFO_RES" "displayName")
USER_NAME_TEXT=$(gp "$INFO_RES" "userName")
SEX_TEXT=$(gp "$INFO_RES" "sex")
EMP_NUM_TEXT=$(gp "$INFO_RES" "employeeNumber")
SCHOOL_NAME_TEXT=$(gp "$INFO_RES" "schoolName")
USER_ID_TEXT=$(gp "$INFO_RES" "id")

echo -e "${C_BOLD}👤 个人档案${C_RES}"
echo -e "${C_GRAY}┌─────────────────────────────────────────────────────────────────────┐${C_RES}"
printf " ${C_BOLD}姓名${C_RES}       : ${C_YLW}%s${C_RES}\n" "$DISPLAY_NAME_TEXT"
printf " ${C_BOLD}账号${C_RES}       : ${C_YLW}%s${C_RES}\n" "$USER_NAME_TEXT"
printf " ${C_BOLD}性别${C_RES}       : %s\n" "$SEX_TEXT"
printf " ${C_BOLD}学号/工号${C_RES}  : %s\n" "$EMP_NUM_TEXT"
printf " ${C_BOLD}学校${C_RES}       : ${C_MAG}%s${C_RES}\n" "$SCHOOL_NAME_TEXT"
printf " ${C_BOLD}用户ID${C_RES}     : ${C_DIM}%s${C_RES}\n" "$USER_ID_TEXT"
echo -e "${C_GRAY}└─────────────────────────────────────────────────────────────────────┘${C_RES}\n"

JSON_DATA="{\"stuId\":\"${USER_ID_TEXT}\",\"page\":1,\"courseName\":\"\",\"courseState\":1,\"openCourseName\":\"\",\"pageSize\":100,\"categoryType\":0}"
COURSE_RES=$(curl -s --connect-timeout 8 --max-time 15 -X POST -H "content-type: application/json" -H "token: $TOKEN_TEXT" -H "user-agent: $UA_TEXT" -d "$JSON_DATA" "${BASE}/course/stuCourse/getStuCourseList")

# ══════════════════════════════════════════════════════════════════════
#  【刷课引擎 纯文本ID入参】
# ══════════════════════════════════════════════════════════════════════
execute_auto_brush() {
    local c_id_t="$1"
    local o_c_id_t="$2"
    local cell_id_t="$3"
    local up_mod_id_t="$4"
    local ctype="$5"
    local cellname="$6"

    (
        local PREVIEW_URL="${BASE}/design/stuCell/getCellPreviewByStu?cellId=${cell_id_t}&openCourseId=${o_c_id_t}&courseId=${c_id_t}&upModuleId=${up_mod_id_t}"
        local PREVIEW_RES=$(curl -s --connect-timeout 8 --max-time 15 -X GET -H "token: $TOKEN_TEXT" -H "User-Agent: $UA_TEXT" "$PREVIEW_URL")

        local TID_T=$(gp "$PREVIEW_RES" "tokenId")
        [ -z "$TID_T" ] || [ "$TID_T" = "null" ] && return

        local RAND_OFF_NUM=$(( $(rand 41) + 10 ))
        local SAVE_URL=""

        if [ "$ctype" = "ppt" ]; then
            local MAXP_NUM=$(( $(rand 61) + 110 ))
            local CT_NUM=$(( MAXP_NUM * 3 + RAND_OFF_NUM ))
            echo -e "        ${C_YLW}⚡ [PPT智能穿透] -> 《${cellname}》 (${MAXP_NUM}页)${C_RES}"
            SAVE_URL="${BASE}/design/study/saveStudyCellInfo?courseId=${c_id_t}&openCourseId=${o_c_id_t}&cellId=${cell_id_t}&studyTime=${CT_NUM}&studyVideoMaxTime=0&studyMaxPage=${MAXP_NUM}&videoTimeTotalLong=0&tokenId=${TID_T}"
        else
            local D_RAW=$(echo "$PREVIEW_RES" | sed -n 's/.*"duration":"\([0-9.]*\)".*/\1/p')
            local D_NUM=$(to_num "$D_RAW")
            local ST_NUM
            if [ "$D_NUM" = "0" ]; then
                ST_NUM=$(( 1000 + RAND_OFF_NUM ))
            else
                local VR_NUM=$(( $(rand 5) + 5 ))
                ST_NUM=$(( D_NUM + VR_NUM ))
            fi
            SAVE_URL="${BASE}/design/study/saveStudyCellInfo?courseId=${c_id_t}&openCourseId=${o_c_id_t}&cellId=${cell_id_t}&studyTime=${ST_NUM}&studyVideoMaxTime=${D_NUM}&studyMaxPage=1&videoTimeTotalLong=${D_NUM}&tokenId=${TID_T}"
        fi
        curl -s --connect-timeout 8 --max-time 15 -X GET -H "token: $TOKEN_TEXT" -H "User-Agent: $UA_TEXT" "$SAVE_URL" > /dev/null
    ) &
}

# ══════════════════════════════════════════════════════════════════════
#  【树形解析 纯文本ID】
# ══════════════════════════════════════════════════════════════════════
parse_tree_node() {
    local cid_t="$1"
    local ocid_t="$2"
    local pid_t="$3"
    local mid_t="$4"
    local clevel_t="$5"
    local indent="$6"

    local API_URL="${BASE}/design/stuCell/getCellListByStu?courseId=${cid_t}&openCourseId=${ocid_t}&parentId=${pid_t}&moduleId=${mid_t}&cellLevel=${clevel_t}&stuId=${USER_ID_TEXT}"
    local NODE_RES=$(curl -s --connect-timeout 8 --max-time 15 -X GET -H "token: $TOKEN_TEXT" -H "User-Agent: $UA_TEXT" "$API_URL")
    local RAW_NODES=$(echo "$NODE_RES" | LC_ALL=C grep -a -o '{"id":"[^"]*"[^}]*}')
    [ -z "$RAW_NODES" ] && return

    local PRE_SORT=""
    local oldIFS="$IFS"
    IFS=$'\n'
    for line in $RAW_NODES; do
        [ -z "$line" ] && continue
        local nid_t=$(echo "$line" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')
        local nname=$(echo "$line" | sed -n 's/.*"cellName":"\([^"]*\)".*/\1/p')
        local ntype_r=$(echo "$line" | sed -n 's/.*"cellType":\([0-9]*\).*/\1/p')
        local nlev_r=$(echo "$line" | sed -n 's/.*"cellLevel":\([0-9]*\).*/\1/p')
        local nproc_r=$(echo "$line" | sed -n 's/.*"cellProcess":\([0-9.]*\).*/\1/p')
        local ncat=$(echo "$line" | sed -n 's/.*"categoryName":"\([^"]*\)".*/\1/p')
        local norder_r=$(echo "$line" | sed -n 's/.*"sortOrder":\([0-9]*\).*/\1/p')
        [ -z "$norder_r" ] && norder_r="999"
        [ -z "$nname" ] && continue
        local norder_n=$(to_num "$norder_r")
        local ntype_n=$(to_num "$ntype_r")
        local nlev_n=$(to_num "$nlev_r")
        local nproc_n=$(to_num "$nproc_r")
        PRE_SORT="${PRE_SORT}${norder_n}|${nid_t}|${nname}|${ntype_n}|${nlev_n}|${nproc_n}|${ncat}"$'\n'
    done
    IFS="$oldIFS"

    # 写入临时文件，杜绝管道子shell污染变量
    echo -n "$PRE_SORT" > "$TMP_SORT_FILE"
    local TOTAL_LINE=$(grep -v '^$' "$TMP_SORT_FILE" | wc -l)
    local CUR_LINE=0
    oldIFS="$IFS"
    IFS=$'\n'
    # 不使用管道sort，文件读取
    for item in $(sort -t'|' -k1,1n "$TMP_SORT_FILE"); do
        [ -z "$item" ] && continue
        CUR_LINE=$((CUR_LINE + 1))
        local idt=$(echo "$item" | cut -d'|' -f2)
        local name=$(echo "$item" | cut -d'|' -f3)
        local ctn=$(echo "$item" | cut -d'|' -f4)
        local cln=$(echo "$item" | cut -d'|' -f5)
        local pn=$(echo "$item" | cut -d'|' -f6)
        local cat=$(echo "$item" | cut -d'|' -f7)

        local BRANCH="├── "
        local NEXT_IND="${indent}│   "
        if [ "$CUR_LINE" -eq "$TOTAL_LINE" ]; then
            BRANCH="└── "
            NEXT_IND="${indent}    "
        fi

        if [ "$ctn" -eq 4 ] || [ "$cln" -le 2 ] || [ -z "$cat" ]; then
            printf "%b%s📁 %b%s%b\n" "$indent" "$BRANCH" "$C_YLW" "$name" "$C_RES"
            parse_tree_node "$cid_t" "$ocid_t" "$idt" "$mid_t" "3" "$NEXT_IND"
        else
            local ICON="📄"
            local CT="ppt"
            if [ "$cat" = "视频" ] || echo "$name" | LC_ALL=C grep -a -qEi "\.(mp4|mkv|avi|flv)$"; then
                ICON="🎬"
                CT="video"
            fi
            printf "%b%s %b %s %b-> 进度: ${C_GRN}%s%%${C_RES}\n" "$indent" "$BRANCH" "$ICON" "$name" "$C_DIM" "$pn"
            if [ "$pn" != "100" ] && [ "$pn" != "100.0" ]; then
                execute_auto_brush "$cid_t" "$ocid_t" "$idt" "${pid_t:-$mid_t}" "$CT" "$name"
            fi
        fi
    done
    IFS="$oldIFS"
    rm -f "$TMP_SORT_FILE"
}

# ══════════════════════════════════════════════════════════════════════
#  【主循环：模块排序改用临时文件，彻底消除管道bad number】
# ══════════════════════════════════════════════════════════════════════
echo -e "${C_BOLD}📚 我的课程表${C_RES}"
echo -e "${C_GRAY}┌─────────────────────────────────────────────────────────────────────┐${C_RES}"

echo "$COURSE_RES" | LC_ALL=C grep -a -o '{"id":"[^"]*"[^}]*}' | while read -r line; do
    CID_T=$(echo "$line" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')
    CNAME=$(echo "$line" | sed -n 's/.*"courseName":"\([^"]*\)".*/\1/p')
    RAW_CID_T=$(echo "$line" | sed -n 's/.*"courseId":"\([^"]*\)".*/\1/p')
    RAW_OCID_T=$(echo "$line" | sed -n 's/.*"openCourseId":"\([^"]*\)".*/\1/p')
    [ -z "$CNAME" ] && continue

    MOD_URL="${BASE}/design/stuCell/getOpenCourseModuleByStu?courseId=${RAW_CID_T}&openCourseId=${RAW_OCID_T}"
    MOD_RES=$(curl -s --connect-timeout 8 --max-time 15 -X GET -H "token: $TOKEN_TEXT" -H "user-agent: $UA_TEXT" "$MOD_URL")

    if echo "$MOD_RES" | LC_ALL=C grep -a -q '"status"\|"error"'; then
        ERRMSG=$(echo "$MOD_RES" | sed -n 's/.*"error":"\([^"]*\)".*/\1/p')
        ESTAT_R=$(echo "$MOD_RES" | sed -n 's/.*"status":\([0-9]*\).*/\1/p')
        ESTAT_N=$(to_num "$ESTAT_R")
        if [ "$ESTAT_N" = "500" ] || [ -n "$ERRMSG" ]; then
            echo -e "  📖 ${C_CYAN}${CNAME}${C_RES}"
            echo -e "     ${C_RED}⚠️ 章节拉取失败 [HTTP ${ESTAT_N:-未知}]${C_RES}"
            echo -e "     ${C_DIM}${ERRMSG:-未知异常}${C_RES}"
            echo -e "${C_GRAY}  ────────────────────────────────────────────────────────────────${C_RES}"
            continue
        fi
    fi

    RAW_MOD=$(echo "$MOD_RES" | LC_ALL=C grep -a -o '{"moduleId":"[^"]*"[^}]*}')
    if [ -z "$RAW_MOD" ]; then
        echo -e "  📖 ${C_CYAN}${CNAME}${C_RES} ${C_DIM}[暂无章节内容]${C_RES}"
        echo -e "${C_GRAY}  ────────────────────────────────────────────────────────────────${C_RES}"
        continue
    fi

    TNAME=$(echo "$line" | sed -n 's/.*"mainTeacherName":"\([^"]*\)".*/\1/p')
    CPROC_R=$(echo "$line" | sed -n 's/.*"process":\([0-9.]*\).*/\1/p')
    CSCORE_R=$(echo "$line" | sed -n 's/.*"stuScore":\([0-9.]*\).*/\1/p')
    CPROC_N=$(to_num "$CPROC_R")
    CSCORE_N=$(to_num "$CSCORE_R")
    [ -z "$CPROC_N" ] && CPROC_N="0"
    [ -z "$CSCORE_N" ] && CSCORE_N="0.0"
    [ -z "$TNAME" ] && TNAME="未知教师"

    echo -e "  📖 ${C_BOLD}${CNAME}${C_RES}"
    echo -e "     👨‍🏫 ${TNAME}  |  📊 进度 ${C_GRN}${CPROC_N}%${C_RES}  |  💯 成绩 ${C_YLW}${CSCORE_N}${C_RES}"
    echo -e "     ${C_DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RES}"

    # 模块列表写入临时文件，禁止管道sort+while
    rm -f "$TMP_SORT_FILE"
    echo "$RAW_MOD" | while read -r modline; do
        MID_T=$(echo "$modline" | sed -n 's/.*"moduleId":"\([^"]*\)".*/\1/p')
        MNAME=$(echo "$modline" | sed -n 's/.*"moduleName":"\([^"]*\)".*/\1/p')
        MTC_R=$(echo "$modline" | sed -n 's/.*"cellCount":\([0-9]*\).*/\1/p')
        MFC_R=$(echo "$modline" | sed -n 's/.*"stuFinishCellCount":\([0-9]*\).*/\1/p')
        MLK_R=$(echo "$modline" | sed -n 's/.*"isLock":\([0-9]*\).*/\1/p')
        MOR_R=$(echo "$modline" | sed -n 's/.*"sortOrder":\([0-9]*\).*/\1/p')
        [ -z "$MOR_R" ] && MOR_R="999"
        [ -z "$MNAME" ] && continue
        MTC_N=$(to_num "$MTC_R")
        MFC_N=$(to_num "$MFC_R")
        MLK_N=$(to_num "$MLK_R")
        MOR_N=$(to_num "$MOR_R")
        echo "${MOR_N}|${MID_T}|${MNAME}|${MTC_N}|${MFC_N}|${MLK_N}" >> "$TMP_SORT_FILE"
    done

    # 从临时文件读取排序结果，彻底规避管道子shell变量类型错乱
    sort -t'|' -k1,1n "$TMP_SORT_FILE" | while read -r modrow; do
        [ -z "$modrow" ] && continue
        midt=$(echo "$modrow" | cut -d'|' -f2)
        mname=$(echo "$modrow" | cut -d'|' -f3)
        totaln=$(echo "$modrow" | cut -d'|' -f4)
        finishn=$(echo "$modrow" | cut -d'|' -f5)
        lockn=$(echo "$modrow" | cut -d'|' -f6)
        [ -z "$totaln" ] && totaln=0
        [ -z "$finishn" ] && finishn=0
        [ -z "$lockn" ] && lockn=0

        MSTAT=""
        if [ "$totaln" -eq 0 ]; then
            MSTAT="${C_GRN}× 无课件${C_RES}"
        elif [ "$totaln" -gt 0 ] && [ "$finishn" -eq "$totaln" ]; then
            MSTAT="${C_GRN}✓ 已学完${C_RES}"
        elif [ "$lockn" -eq 1 ]; then
            MSTAT="${C_RED}🔒 未解锁${C_RES}"
        else
            MSTAT="${C_YLW}▶ 学习中${C_RES}"
        fi
        echo -e "     ├─ 📂 ${mname} ${MSTAT} (${finishn}/${totaln})"
        if [ "$totaln" -eq 0 ] || [ "$finishn" -eq "$totaln" ] || [ "$lockn" -eq 1 ]; then
            continue
        fi
        parse_tree_node "$RAW_CID_T" "$RAW_OCID_T" "" "$midt" "2" "     │  "
    done
    rm -f "$TMP_SORT_FILE"
    echo -e "${C_GRAY}  ────────────────────────────────────────────────────────────────${C_RES}"
done

echo -e "${C_GRAY}└─────────────────────────────────────────────────────────────────────┘${C_RES}\n"

wait
rm -f "$TMP_SORT_FILE"

# ══════════════════════════════════════════════════════════════════════
#  任务报告
# ══════════════════════════════════════════════════════════════════════
echo -e "${C_BOLD}${C_CYAN}╔══════════════════════════════════════════════════════════════════════╗${C_RES}"
echo -e "${C_BOLD}${C_CYAN}║                      🎉 本次学习任务报告                              ║${C_RES}"
echo -e "${C_BOLD}${C_CYAN}╠══════════════════════════════════════════════════════════════════════╣${C_RES}"
echo -e "${C_BOLD}${C_CYAN}║${C_RES}  ${C_GRN}✔${C_RES}  所有未完结课件已提交后台处理                              ${C_BOLD}${C_CYAN}║${C_RES}"
echo -e "${C_BOLD}${C_CYAN}║${C_RES}  ${C_YLW}⚡${C_RES}  PPT智能防锁死引擎已激活（仅针对未完结课件）                ${C_BOLD}${C_CYAN}║${C_RES}"
echo -e "${C_BOLD}${C_CYAN}║${C_RES}  ${C_DIM}ℹ️${C_RES}  已学完课件保持静默，数据同步存在延迟，请稍后刷新网页查看    ${C_BOLD}${C_CYAN}║${C_RES}"
echo -e "${C_BOLD}${C_CYAN}╚══════════════════════════════════════════════════════════════════════╝${C_RES}\n"
