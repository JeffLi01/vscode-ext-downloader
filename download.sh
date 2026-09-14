#!/usr/bin/env bash
set -euo pipefail

VSIX_DIR="./vsix"
mkdir -p "${VSIX_DIR}"
success=0
fail=0
retry_times=1

# 浏览器UA与请求头
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
HDR_ACCEPT="Accept: application/octet-stream,*/*;q=0.8"
HDR_ACCEPT_LANG="Accept-Language: zh-CN,zh;q=0.9,en;q=0.8"
HDR_ACCEPT_ENC="Accept-Encoding: gzip, deflate, br"

echo "========================================"
echo "✅ VSCode 插件批量下载脚本（模拟浏览器UA）"
echo "========================================"
echo

# 检查 code / curl
if ! command -v code &> /dev/null; then
    echo "❌ code 命令未找到，请确认 VSCode 已加入 PATH"
    exit 1
fi
if ! command -v curl &> /dev/null; then
    echo "❌ curl 未安装"
    exit 1
fi

echo "🔍 获取本地插件列表..."
EXT_LIST=$(code --list-extensions --show-versions)
if [[ -z "${EXT_LIST}" ]]; then
    echo "❌ 没有读取到任何插件"
    exit 1
fi

while IFS= read -r line; do
    [[ -z "${line}" ]] && continue

    IFS='@' read -r full_id ver <<< "${line}"
    pub="${full_id%%.*}"
    ext="${full_id#*.}"

    filename="${full_id}-${ver}.vsix"
    outpath="${VSIX_DIR}/${filename}"
    dl_url="https://${pub}.gallery.vsassets.io/_apis/public/gallery/publisher/${pub}/extension/${ext}/${ver}/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage"

    echo "[$(date +%H:%M:%S)] ⬇️ ${full_id} v${ver}"
    echo "    Publisher: ${pub}  Ext: ${ext}"
    echo "    File: ${filename}"

    # 校验已有文件：PK zip头
    if [ -f "${outpath}" ]; then
        header=$(head -c4 "${outpath}" | xxd -p)
        if [[ "${header}" == "504b0304" ]]; then
            echo "    ⏭️ 文件已存在且合法，跳过"
            ((success++))
            echo
            continue
        else
            echo "    ⚠️ 旧文件无效，删除重下"
            rm -f "${outpath}"
        fi
    fi

    # 带浏览器头下载，--fail 4xx/5xx直接报错
    ok=0
    for ((i=0; i<=retry_times; i++)); do
        if curl --fail --connect-timeout 30 -sSL \
            -A "${UA}" \
            -H "${HDR_ACCEPT}" \
            -H "${HDR_ACCEPT_LANG}" \
            -H "${HDR_ACCEPT_ENC}" \
            -o "${outpath}" "${dl_url}"; then
            ok=1
            break
        fi
        echo "    ⚠️ 第${i}次下载失败，重试..."
        sleep 1
    done

    if [ ${ok} -eq 1 ]; then
        header=$(head -c4 "${outpath}" | xxd -p)
        if [[ "${header}" == "504b0304" ]]; then
            echo "    ✅ 下载成功，合法VSIX"
            ((success++))
        else
            echo "    ❌ 返回内容不是zip包（CDN返回非二进制）"
            rm -f "${outpath}"
            ((fail++))
        fi
    else
        echo "    ❌ HTTP下载失败"
        rm -f "${outpath}"
        ((fail++))
    fi
    echo

done <<< "${EXT_LIST}"

echo "========================================"
echo "🎉 任务结束！成功: ${success}  失败: ${fail}"
echo "插件保存在: ${VSIX_DIR}"
echo "========================================"
